### \\\ HomeLab - Infra_As_Code ///

### Goal:
- Using Terraform to create a number of master nodes and worker nodes determined by the user.
    - Terraform triggering an ignition script which configures the kube cluster and any software requirements for a minimum viable cluster.
    - Adding feature to update nodes one at a time by destroying the old and deploying new nodes at a newer version. 


### Prerequisites: 
- Virsh / Virtual Machine Manager installed
    - Two storage clusters configured, one to store the ISO's/QCOW's and the other for additional disk space.
    - Two Virtual Networks one for Internet Access named 'default', the Second for Kube Cluster connectivitity named 'kube_net'.

- Manually install the FCCT tool (https://github.com/coreos/butane/releases) and run:
    - $ sudo chmod a+x fcct; sudo mv fcct /usr/local/bin

- Download the Fedora CoreOS qcow image and save it to your storage cluster.
    - Fedora CoreOS QEMU qcow2.xz (https://fedoraproject.org/coreos/download?stream=stable)
    - $  xz -d fedora-coreos-*.qcow2.xz

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

---

### Still in Progress:
- Working on fixing the ignition script which bootstraps the kubernetes cluster. Still seeing errors.
- Need to cleanup main.tf to remove explicit references to the cluster name ("hawk" in this case), and pass all naming via the variables.tf file.
- Remove disk sizes from main.tf and pass master and worker disk space parameters via variables.tf.
