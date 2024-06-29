# Edge Lab Kubernetes Setup

This is a baremetal kubernetes setup, using Cluster API and the Metal3.

## Getting started 

### Required components
- Infrastructure kubernetes cluster - In this case I've deployed a single node k3s cluster on a VM with their [kickstart script](https://docs.k3s.io/quick-start)
- Hardware - I'm using 3 Optiplex 3060s and 3 Lenovo M920Qs. Any machines will do, but prefereably they have Intel AMT (not a hard requirement)
- TPLink Tapo P100 smart plugs - To act as BMC with non AMT compatible machines
- [Sushy Tools with baremetal driver](https://github.com/ashmantis1/sushy-tools-baremetal)
- CLI tools: kubectl, clusterctl and fluxctl are all recommended, although only kubectl is required. 

### Deploying Sushy Tools
In the `examples/` directory, there is a Sushy Tools kubernetes deployment. This deploys sushy tools with a secret containing an example config required for controlling both Intel AMT, and Tapo smart plugs. This is used to allow Ironic to control the nodes power state remotely.

### Creating the node image
I'm using Bootc in order to create the Kubernetes node operating system images. The benefits of this are that the images are immutable, consistent, and can be easily modified as necessary. However, this does mean that any changes to the underlying OS require a full reprovision, so make sure the Dockerfile contains all required software.

In order to build the image, I've provided the ansible playbook: `node-image/build.yml`. This playbook runs through all the steps to build the container, create a RAW or QCOW2, and serve it with nginx. This should be run from your infrastructure cluster, as it is the best place to host your images. In the future I will add functionality to deploy the image hosting to kubernetes instead of just a podman container.

Modifying elements such as the Kubernetes Version, image name/repository/tag and webserver port are as simple as editing the vars file. To change what is installed in the image itself, modify the Dockerfile. You can also include Jinja2 templates in `node-image/templates` which will be templated into the files directory, but currently you must add them manually in the Dockerfile. The script supports creating both RAW and QCOW2 images, depending on which you create, you will need to patch the Machine Templates used to create the cluster.

To build the image, run: 

`ansible-playbook node-image/build.yaml -K`

I will provide some prebuilt containers as packages in this repository, but customisation is recommended.

### Modifying the Clusters
The clusters being deployed are in the `kubernetes/clusters/overlays` directory. Currently I've tested this setup with the ClusterAPI KubeadmControlPlane and KubeadmBootstrap providers, so the base cluster in `kubernetes/clusters/bases` is a Kubeadm based cluster.
When creating a cluster in overlays, there are a few things you need to do: 
- Create a Kustomization which points to the overlay, preferably in `kubernetes/clusters/overlay/<cluster name>.yaml`. This Kustomization should contain the required PostBuild paramaters as seen in the existing cluster.
- Create BareMetalHost files which correspond with each one of your nodes. The BMC field should point to the Hostname/IP of your Redfish Emulator, with the format: `redfish+http://<host/ip of emulator>/redfish/v1/Systems/<name of host in sushy tools>`
- Create a credential secret. Currently Sushy Tools Baremetal doesn't support authenticated redfish, but Metal3 requires a secret reference in order for it to accept the host
- Fill out all other necessary fields, such as `rootDeviceHints` and others, in order for the BMC to properly provision. More information can be found at: https://github.com/metal3-io/baremetal-operator/blob/main/docs/api.md
- Copy Bootstrap example as found in the current cluster, and modify as required.

### Running Bootstrap
Bootstrapping the infrastructure is as simple as running: 

`flux bootstrap git --url='ssh://git@github.com/ashmantis1/edge-lab-infra.git' --private-key-file=<key file> --path=kubernetes/flux`

This will deploy FluxCD and and the clusters which are enabled in the `kubernetes/clusters/overlays/kustomization.yaml` file, along with the required infrastructure apps found in `kubernetes/infrastructure`, most important of which is Metal3. The current Metal3 deployment is not ideal, and will be cleaned up in the future.

Some useful commands to watch the deployment: 

- `clusterctl describe cluster <cluster name>` - This will show you the state of the cluster according to ClusterAPI
- `kubectl get baremetalhosts` - This will show you all the BareMetalHosts and their current state
- `kubectl logs -f deployment/ironic -n baremetal-operator-system -c ironic` - Show you the logs for the ironic deployment
- `kubectl logs -f deployment/baremetal-operator -n baremetal-operator-system` - Shows the logs for the baremetal operator

Once the cluster has been deployed, you can get the kubeconfig by running: 

`clusterctl get kubeconfig <cluster name> > ~/.ssh/kubeconfig && export KUBECONFIG=~/.ssh/kubeconfig`

Now all kubectl commands will be run against the cluster you deployed.

### Upgrading the cluster 
Currently to upgrade the cluster, new Metal3MachineTemplates need to be created for both the workers and masters, and the KubeadmControlPlane and MachineDeployments must be updated accordingly. This will schedule an in-place rollout where nodes will be deleted and re-provisioned one by one, until the cluster is updated.
More information can be found at these sites:
- https://cluster-api.sigs.k8s.io/tasks/upgrading-clusters
- https://book.metal3.io/capm3/node_reuse - Needs to be configured in order for Scale-In to function
  
## How it all Works

### Sushy Tools 
This project is  made possible through the use of the [Sushy Tools Redfish Emulator](https://docs.openstack.org/sushy/latest/). This emulator provides a Redfish Endpoint, which is required by Ironic and therefore Metal3, in order to control power state and provision nodes. However, the emulator does not have any support for baremetal power control (because why would it lol) out of the box. To solve this "issue", I wrote a [driver for Sushy Tools](https://github.com/ashmantis1/sushy-tools-baremetal). This driver adds the ability to control two specific power control methods: 

- Intel AMT
- TPLink Tapo P100 Smart Plugs

Intel AMT is an obvious solution, as it is a BMC commonly available on consumer machines (technically it's supported by a third party Ironic driver as well, but it isn't supported by Metal3). However when planning this project, I also bought some machines which did not include AMT or any other form of remote power control. While options such as PiKVM seemed promising, they did not prove to be particularly cost effective. Instead, I went out and bought some WiFi smart plugs, which could be controlled via a local API (making sure to buy ones which did not require an internet connection). At about $15 each, these seemed to be a cheap and easy way to provide BMC. 

I still needed a way for Metal3 to interact with the "BMC" options I had come up with, so I decided to write a driver for Sushy Tools. The baremetal driver works by making use of the Fake Driver provided by Sushy Tools. This Fake Driver provides all the same endpoints as a real Redfish device, and out of the box will respond to all requests (including POST and PATCH). It does this by storing and updating data in an SQLite database, including things sucha as power state. I created a copy of this file, which would act as the base for the driver. I then added config options for the new driver, to allow it to be selected for use. To control the Tapo smart plugs, I used the [PyP100 python library](https://github.com/fishbigger/TapoP100/blob/main/PyP100/PyP100.py). This meant that all I needed to do was replace the Fake Drivers power state functionality, with function calls to this library, pulling from the configuration file to get things like IP addresses of the nodes. 

Ironic only really* cares about three things: 

- Power State
- Power On
- Power Off

However, Ironic does try to get a lot of other information from the Redfish endpoint during host inspection. Luckily as I mentioned earlier, Sushy Tools Fake Driver provides every endpoint. This meant I could leave most of the "unnecessary" endpoints as they were, because even though the results they would return might not be accurate, it wouldn't affect the functionality with Metal3.

With all the important endpoints implemented (all very similar for AMT but a little simpler), I started testing the functionality of the emulator. Initially, everything seemed promising. I tested doing basic requests to control power state using curl, which worked perfectly. I then created a BareMetalHost resource in my kubernetes cluster, pointing it to the Redfish emulator in the BMC field. This worked at first. The node would spin to life and boot using the PXE server provider by the Ironic deployment (I was pretty excited when I first saw that). However, occasionally there would be no response when Ironic would request the node to power on. After a little bit of troubleshooting, I realised that the Tapo smart plugs were essentially being DOS'd by Ironic. Because Ironic tries to get the nodes power state every few seconds, the little microcontrontrollers in the smart plugs couldn't keep up, and stopped responding to requests, which caused Ironic to enter error states. 

To fix this issue, I used the SQLite database already provided in the Fake Driver to cache the current power state of a node. This means that when a request to get the current power state is made, the driver will respond with the same power state for about 30 seconds after the last state was pulled from the plugs. After that period elapses, any future request will  call the plugs API directly, and start the countdown again. After this fix was implemented, the node was now (relatively) consistently turning on and off as Ironic requested. 

With BMC out of the way, now came deploying the cluster...

### Metal3 and Cluster API 

