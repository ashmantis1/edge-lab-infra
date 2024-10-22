# Edge Lab Infrastructure

This is a baremetal kubernetes setup, using Cluster API and the Metal3. It allows automatic and dynamic node provisioning with non enterprise equipment.

For more information about the project see: https://docs.ashmantis.com/edge-lab-infra/how-and-why

## Getting started 

### Required components
- Infrastructure kubernetes cluster - In this case I've deployed a single node k3s cluster on a VM with their [kickstart script](https://docs.k3s.io/quick-start)
- Hardware - I'm using 3 Optiplex 3060s and 3 Lenovo M920Qs. Any machines will do, but preferably they have Intel AMT (not a hard requirement)
- TPLink Tapo P100 smart plugs - To act as BMC with non AMT compatible machines
- [Sushy Tools with baremetal driver](https://github.com/ashmantis1/sushy-tools-baremetal)
- CLI tools: kubectl, clusterctl and fluxctl are all recommended, although only kubectl is required. 

### Deploying Sushy Tools
In the `examples/` directory, there is a Sushy Tools kubernetes deployment. This deploys sushy tools with a secret containing an example config required for controlling both Intel AMT, and Tapo smart plugs. This is used to allow Ironic to control the nodes power state remotely. See the Sushy Tools baremetal repository for more info.

### Creating the node image
This project is using Bootc in order to create the Kubernetes node operating system images. The benefits of this are that the images are immutable, consistent, and can be easily modified as necessary. Updates can be performed either by bootc's update mechanism, which pulls the latest version of the build container, or by performing a rolling reprovisioning with a new image, by ClusterAPI.

In order to build the image, I've provided the ansible playbook: `node-image/build.yml`. This playbook runs through all the steps to build the container, create a RAW or QCOW2, and serve it with nginx. This should be run from your infrastructure cluster, as it is the best place to host your images. In the future I will add functionality to deploy the image hosting to kubernetes instead of just a podman container.

Modifying elements such as the Kubernetes Version, image name/repository/tag and webserver port are as simple as editing the vars file. To change what is installed in the image itself, modify the Dockerfile. You can also include Jinja2 templates in `node-image/templates` which will be templated into the files directory, but currently you must add them manually in the Dockerfile. The script supports creating both RAW and QCOW2 images, depending on which you create, you will need to patch the Machine Templates used to create the cluster.

To build the image, run: 

`ansible-playbook node-image/build.yaml -K`

A prebuilt container is provided, but building your own is recommended.

### Modifying the Clusters
The clusters being deployed are in the `kubernetes/clusters/overlays` directory. Currently I've tested this setup with the ClusterAPI KubeadmControlPlane and KubeadmBootstrap providers, so the base cluster in `kubernetes/clusters/bases` is a Kubeadm based cluster.
When creating a cluster in overlays, there are a few things you need to do: 
- Create a Kustomization which points to the overlay, preferably in `kubernetes/clusters/overlay/<cluster name>.yaml`. This Kustomization should contain the required PostBuild parameters as seen in the existing cluster.
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

### Updating and Upgrading the cluster 
To update the OS system packages, the node image container can be rebuilt and pushed to the container repository. You can then run `bootc update --apply --quiet` on each node. This will reboot the node, and deploy the updated image without overwriting other files. I have disabled the automatic bootc updates, as it brings nodes down without marking them unschedulable which could be problematic when the cluster is in use. This method is not ideal for updating the kubernetes version, as ClusterAPI is not aware of the system package updates.

To update the Kubernetes version of the cluster, a new node image must be built with the required version and made available over HTTP (see building the node image above). Then, new Metal3MachineTemplates need to be created for both the workers and masters, and the KubeadmControlPlane and MachineDeployments must be updated to refer to the new templates. Both those resources' kubernetes versions must also be made to match the desired version. This will schedule an in-place rollout where nodes will be deleted and re-provisioned one by one, until the cluster is updated. This should not cause down time, as pods will reschedule as the nodes are reprovisioned.

More information can be found at these sites:
- https://cluster-api.sigs.k8s.io/tasks/upgrading-clusters
- https://book.metal3.io/capm3/node_reuse - Needs to be configured in order for Scale-In to function

  

