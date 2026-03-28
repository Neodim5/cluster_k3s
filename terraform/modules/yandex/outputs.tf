# Master nodes output
output "master_nodes" {
  description = "List of master node information"
  value = [
    for idx, vm in yandex_compute_instance.masters : {
      name       = vm.name
      ip         = vm.network_interface.0.ip_address
      external_ip = var.external_ip ? vm.network_interface.0.nat_ip_address : null
      instance_id = vm.id
      zone        = vm.zone
    }
  ]
}

# Worker nodes output
output "worker_nodes" {
  description = "List of worker node information"
  value = [
    for idx, vm in yandex_compute_instance.workers : {
      name       = vm.name
      ip         = vm.network_interface.0.ip_address
      external_ip = var.external_ip ? vm.network_interface.0.nat_ip_address : null
      instance_id = vm.id
      zone        = vm.zone
    }
  ]
}

# Cluster endpoint (first master)
output "cluster_endpoint" {
  description = "K3S cluster API endpoint"
  value       = length(yandex_compute_instance.masters) > 0 ? "https://${yandex_compute_instance.masters[0].network_interface.0.ip_address}:6443" : null
}

# All nodes output
output "all_nodes" {
  description = "List of all node information with roles"
  value = concat(
    [
      for idx, vm in yandex_compute_instance.masters : {
        name       = vm.name
        ip         = vm.network_interface.0.ip_address
        external_ip = var.external_ip ? vm.network_interface.0.nat_ip_address : null
        instance_id = vm.id
        zone        = vm.zone
        role        = "master"
      }
    ],
    [
      for idx, vm in yandex_compute_instance.workers : {
        name       = vm.name
        ip         = vm.network_interface.0.ip_address
        external_ip = var.external_ip ? vm.network_interface.0.nat_ip_address : null
        instance_id = vm.id
        zone        = vm.zone
        role        = "worker"
      }
    ]
  )
}

# Ansible inventory hosts
output "inventory_hosts" {
  description = "Ansible inventory compatible string"
  value = <<-EOF
[masters]
%{for idx, vm in yandex_compute_instance.masters}${vm.name} ansible_host=${vm.network_interface.0.ip_address}%{if var.external_ip && vm.network_interface.0.nat_ip_address != ""} ansible_ssh_host=${vm.network_interface.0.nat_ip_address}%{endif}
%{endfor}
[workers]
%{for idx, vm in yandex_compute_instance.workers}${vm.name} ansible_host=${vm.network_interface.0.ip_address}%{if var.external_ip && vm.network_interface.0.nat_ip_address != ""} ansible_ssh_host=${vm.network_interface.0.nat_ip_address}%{endif}
%{endfor}
[k3s_cluster:children]
masters
workers
EOF
}

# Image ID used
output "image_id" {
  description = "ID of the OS image used for instances"
  value       = data.yandex_compute_image.ubuntu.image_id
}
