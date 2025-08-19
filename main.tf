terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
    ct = {
      source  = "poseidon/ct"
      version = "0.12.0" # or current
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# --- Base OS Image ---
resource "libvirt_volume" "fcos_base" {
  name   = "fcos_base.qcow2"
  pool   = var.storage_pool
  source = var.coreos_image_path 
  format = "qcow2"
}

# --- Master: FCCT -> Ignition ---
resource "local_file" "master_fcct" {
  count    = var.master_count
  filename = "${path.module}/fcct/master-${format("%02d", count.index + 1)}.fcct.yaml"
  content  = templatefile("${path.module}/templates/master.fcct.yaml", {
    cluster_name           = var.cluster_name
    master_index           = format("%02d", count.index + 1)
    master_name            = "${var.cluster_name}-master-${format("%02d", count.index + 1)}"
    master_is_primary      = count.index == 0
    pod_network_cidr       = var.pod_network_cidr
    control_plane_endpoint = var.control_plane_endpoint
    primary_master_host    = "${var.cluster_name}-master-01"
  })
}

data "ct_config" "master" {
  count        = var.master_count
  content      = templatefile("${path.module}/templates/master.fcct.yaml", {
    cluster_name           = var.cluster_name
    master_index           = format("%02d", count.index + 1)
    master_name            = "${var.cluster_name}-master-${format("%02d", count.index + 1)}"
    master_is_primary      = count.index == 0
    pod_network_cidr       = var.pod_network_cidr
    control_plane_endpoint = var.control_plane_endpoint
    primary_master_host    = "${var.cluster_name}-master-01"
  })
  strict       = true
  pretty_print = false
}

resource "libvirt_ignition" "master" {
  count   = var.master_count
  name    = "master-${format("%02d", count.index + 1)}.ign"
  content = data.ct_config.master[count.index].rendered
}


# --- Workers: FCCT -> Ignition ---
### Render worker fcct(s) from template 

resource "local_file" "worker_fcct" {
  count    = var.worker_count
  filename = "${path.module}/fcct/worker-${format("%02d", count.index + 1)}.fcct.yaml"
  content  = templatefile("${path.module}/templates/worker.fcct.yaml", {
    worker_index = format("%02d", count.index + 1)
    worker_name  = "${var.cluster_name}-worker-${format("%02d", count.index + 1)}"
    cluster_name = var.cluster_name
  })
}

# Transpile FCCT -> Ignition at plan time
data "ct_config" "worker" {
  count        = var.worker_count
  content      = templatefile("${path.module}/templates/worker.fcct.yaml", {
    worker_index = format("%02d", count.index + 1)
    worker_name  = "${var.cluster_name}-worker-${format("%02d", count.index + 1)}"
    cluster_name = var.cluster_name
  })
  strict       = true
  pretty_print = false
}

resource "libvirt_ignition" "worker" {
  count   = var.worker_count
  name    = "worker-${format("%02d", count.index + 1)}.ign"
  content = data.ct_config.worker[count.index].rendered
}

# --- Master OS disk ---
resource "libvirt_volume" "hawk_master_os_disk" {
  count  = var.master_count
  name   = "${var.cluster_name}_master_${format("%02d", count.index + 1)}"
  pool   = var.storage_pool
  base_volume_id = libvirt_volume.fcos_base.id
  format = "qcow2"
  size   = 322122547200 # 300 GB

  lifecycle {
    replace_triggered_by = [libvirt_ignition.master[count.index]]
  }
}

# --- Master Data disk (200GB) ---
resource "libvirt_volume" "hawk_master_data_disk" {
  count  = var.master_count
  name   = "${var.cluster_name}_master_data_${format("%02d", count.index + 1)}"
  pool   = var.storage_pool
  format = "qcow2"
  size   = 214748364800 # 200 GB
}

# --- Master Node ---
resource "libvirt_domain" "hawk_masters" {
  count  = var.master_count
  name   = "${var.cluster_name}-master-${format("%02d", count.index + 1)}"
  memory = var.master_memory
  vcpu   = var.master_cpu

  lifecycle {
    replace_triggered_by = [libvirt_ignition.master[count.index]]
  }

  disk { volume_id = libvirt_volume.hawk_master_os_disk[count.index].id }
  disk { volume_id = libvirt_volume.hawk_master_data_disk[count.index].id }

  network_interface { network_name = "default" }
  network_interface { network_name = "kube_net" }

  coreos_ignition = libvirt_ignition.master[count.index].id
}



# --- Worker OS disks (300GB) ---
resource "libvirt_volume" "hawk_worker_os_disks" {
  count  = var.worker_count 
  name   = "${var.cluster_name}_worker_${format("%02d", count.index + 1)}"
  pool   = var.storage_pool
  base_volume_id = libvirt_volume.fcos_base.id
  format = "qcow2"
  size   = 322122547200

  lifecycle {
    replace_triggered_by = [libvirt_ignition.worker[count.index]]
  }
}

# --- Worker Data disks (500GB each) ---
resource "libvirt_volume" "hawk_worker_data_disks" {
  count  = var.worker_count
  name   = "${var.cluster_name}_worker_data_${format("%02d", count.index + 1)}"
  pool   = var.storage_pool
  format = "qcow2"
  size   = 536870912000 # 500 GB
}

# --- Worker Nodes ---
resource "libvirt_domain" "hawk_workers" {
  count  = var.worker_count
  name   = "${var.cluster_name}-worker-${format("%02d", count.index + 1)}"
  memory = var.worker_memory
  vcpu   = var.worker_cpu

  lifecycle {
    #create_before_destroy = true
    replace_triggered_by = [libvirt_ignition.worker[count.index]]
  }

  disk { volume_id = libvirt_volume.hawk_worker_os_disks[count.index].id }
  disk { volume_id = libvirt_volume.hawk_worker_data_disks[count.index].id }

  network_interface { network_name = "default" }
  network_interface { network_name = "kube_net" }

  coreos_ignition = libvirt_ignition.worker[count.index].id 
  }
