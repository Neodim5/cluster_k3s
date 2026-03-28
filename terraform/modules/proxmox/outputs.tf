# Master nodes output
output "master_nodes" {
  description = "List of master node information"
  value = [
    for idx, vm in proxmox_vm_qemu.masters : {
      name = vm.name
      ip   = split(",", vm.ipconfig0)[0]
      vmid = vm.vmid
    }
  ]
}

# Worker nodes output
output "worker_nodes" {
  description = "List of worker node information"
  value = [
    for idx, vm in proxmox_vm_qemu.workers : {
      name = vm.name
      ip   = split(",", vm.ipconfig0)[0]
      vmid = vm.vmid
    }
  ]
}

# Cluster endpoint
output "cluster_endpoint" {
  description = "K3S cluster API endpoint"
  value       = length(proxmox_vm_qemu.masters) > 0 ? "https://${split(",", proxmox_vm_qemu.masters[0].ipconfig0)[0]}:6443" : null
}

# All nodes output
output "all_nodes" {
  description = "List of all node information"
  value = concat(
    [
      for idx, vm in proxmox_vm_qemu.masters : {
        name = vm.name
        ip   = split(",", vm.ipconfig0)[0]
        vmid = vm.vmid
        role = "master"
      }
    ],
    [
      for idx, vm in proxmox_vm_qemu.workers : {
        name = vm.name
        ip   = split(",", vm.ipconfig0)[0]
        vmid = vm.vmid
        role = "worker"
      }
    ]
  )
}
