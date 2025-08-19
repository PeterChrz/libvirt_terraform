output "master_ips" {
  value = [for d in libvirt_domain.hawk_masters : d.network_interface[1].addresses]
}

output "worker_ips" {
  value = [for vm in libvirt_domain.hawk_workers : vm.network_interface[1].addresses]
}

