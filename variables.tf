variable "cluster_name" {
  default = "hawk"
}

variable "master_memory" {
  default = 8192
}

variable "worker_memory" {
  default = 16384
}

variable "master_cpu" {
  default = 2
}

variable "worker_cpu" {
  default = 2
}

variable "coreos_image_path" {
  default = "/hdd_cluster/iso/fedora-coreos-42.20250705.3.0-qemu.x86_64.qcow2"
  description = "Path to the Fedora CoreOS base qcow2 image"
}

variable "worker_count" {
  description = "Number of worker nodes to create"
  type        = number
  default     = 1
}

variable "master_count" {
  description = "Number of master nodes to create"
  type        = number
  default     = 1
}

variable "storage_pool" {
  default = "hdd_cluster"
}

variable "pod_network_cidr" {
  type        = string
  default     = "172.18.0.0/16"
  description = "Cluster pod CIDR used by your CNI"
}

variable "control_plane_endpoint" {
  description = "Stable LB/VIP DNS or IP for Kubernetes API (optional)"
  type        = string
  default     = ""
}