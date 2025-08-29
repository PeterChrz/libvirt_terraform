### \\\ HomeLab - Infra_As_Code ///

### Goal:
- Using Terraform to create a number of master nodes and worker nodes determined by the user.
    - Terraform triggering an ignition script which configures the kube cluster and any software requirements for a minimum viable cluster.
    - Adding feature to update nodes one at a time by destroying the old and deploying new nodes at a newer version. 


### Prerequisites: 
- Virsh / Virtual Machine Manager installed
    - Two storage clusters configured, one to store the ISO's/QCOW's and the other for additional disk space.
    - Two Virtual Networks one for Internet Access named 'default', the Second for Kube Cluster connectivitity named 'kube_net'.
      - Bridge default network with your local network.

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

### Divided Disks
In the current config, each VM gets two disks. A smaller OS disk and a larger storage disk. For the master node it looks something like this.

```
core@hawk-master-01:~$ lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
vda    253:0    0   200G  0 disk 
├─vda1 253:1    0     1M  0 part 
├─vda2 253:2    0   127M  0 part 
├─vda3 253:3    0   384M  0 part /boot
└─vda4 253:4    0 199.5G  0 part /var
                                 /sysroot/ostree/deploy/fedora-coreos/var
                                 /etc
                                 /sysroot
vdb    253:16   0   300G  0 disk 
└─vdb1 253:17   0   300G  0 part /var/lib/k8s/containers/storage/overlay
                                 /var/lib/containers/storage/overlay
                                 /var/lib/etcd
                                 /var/lib/kubelet
                                 /var/lib/containers
                                 /var/lib/k8s
```

This divides the processing, and prevents any unanticipated storage growth from locking up the root filesystem. 

To provide greater performance gains you can seperate the class of disk the OS disk is created on from the class of disk the Storage disk is created on. Currently everything sits on an HDD_Cluster, this is set in variables.tf. We can add additional storage pools there. (to be added)


### Dual NICs
Each VM is created with two NICs. One intented to be bridged to your local network. The second as a kube_net specific to kubernetes api server communications. The intention is to reduce noise and to isolate communications. 
I will provide steps to bridge your local network with the default VM network that virt manager provides. 


---

### Still in Progress:
- Need to cleanup main.tf to remove explicit references to the cluster name ("hawk" in this case), and pass all naming via the variables.tf file.
- Remove disk sizes from main.tf and pass master and worker disk space parameters via variables.tf.
- Confirm Cillium is actually being used. 
- Test multi-node creation and validate all nodes join the cluster. 
- Create an SSD_Cluster storage pool to test tiered storage performance. 
- When first built I'm seeing the master VM restart 3 times. I need to better understand what happens that 3rd time. 
