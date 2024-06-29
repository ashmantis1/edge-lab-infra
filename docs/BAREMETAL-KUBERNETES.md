layout: page

title: "Baremetal Kubernetes" 

permalink: /edge-lab-infra/how-and-why

# Baremetal Kubernetes with a twist

If you want to get started head to the [edge-lab-infra](https://github.com/ashmantis1/edge-lab-infra) repository.

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

