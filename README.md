### \\\ HomeLab - Infra_As_Code ///

### Goal:
- Terraform creates user selected number of master nodes and worker nodes.
    - Terraform triggers ignition script which configures the kube cluster and any software requirements for minimum viable cluster.


### Prerequisites: 
- Virsh / Virtual Machine Manager installed
    - Two storage clusters configured, one to store the ISO's/QCOW's and the other for additional disk space.
    - Two Virtual Networks one for Internet Access, the Second for Kube Cluster connectivitity.

- Manually install the FCCT tool (https://github.com/coreos/butane/releases) and run:
    - $ sudo chmod a+x fcct; sudo mv fcct /usr/local/bin

- Download the Fedora CoreOS qcow image and save it to your storage cluster.
    - Fedora CoreOS QEMU qcow2.xz (https://fedoraproject.org/coreos/download?stream=stable)
    - $  xz -d fedora-coreos-*.qcow2.xz

- Two Network Devices within Virtual Machine Manager, one for general use named "default" and another for control plane communication named "kube_net".

---

### Logging into Master Node:
- Find the IP of the newly created master node 01. 
    - `# virsh list`
    - `# virsh domifaddr hawk-master-01`
    - `# ssh core@192.168.122.175`

```
$ virsh domifaddr hawk-master-01
 Name       MAC address          Protocol     Address
-------------------------------------------------------------------------------
 vnet37     52:54:00:82:0e:81    ipv4         192.168.122.175/24
 vnet38     52:54:00:aa:9f:c3    ipv4         10.10.10.215/24
```
