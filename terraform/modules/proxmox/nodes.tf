# K3S Master Nodes
resource "proxmox_vm_qemu" "masters" {
  count       = var.master_count
  name        = "${var.environment}-k3s-master-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.vm_template_id
  
  # VM resources based on template
  cores  = var.master_config.cpu_cores
  memory = var.master_config.memory_gb
  
  # Disk configuration
  disk {
    slot     = 0
    size     = "${var.master_config.disk_gb}G"
    type     = "scsi"
    storage  = var.storage
    iothread = true
  }
  
  # Network configuration
  network {
    id     = 0
    model  = "virtio"
    bridge = var.network_bridge
  }
  
  # Cloud-init configuration
  os_type = "cloud-init"
  
  sshkeys = <<EOF
${var.ssh_public_key}
EOF
  
  # Static IP assignment
  ipconfig0 = "ip=${var.master_ips[count.index]}/24,gw=${var.gateway}"
  
  nameserver = join(" ", var.dns_servers)
  
  # Boot settings
  boot = "order=scsi0"
  
  # QEMU agent
  agent = 1
  
  # Tags for identification
  tags = join(";", [
    "k3s",
    "master",
    var.environment
  ])
  
  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }
}

# K3S Worker Nodes
resource "proxmox_vm_qemu" "workers" {
  count       = var.worker_count
  name        = "${var.environment}-k3s-worker-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.vm_template_id
  
  # VM resources based on template
  cores  = var.worker_config.cpu_cores
  memory = var.worker_config.memory_gb
  
  # Disk configuration
  disk {
    slot     = 0
    size     = "${var.worker_config.disk_gb}G"
    type     = "scsi"
    storage  = var.storage
    iothread = true
  }
  
  # Network configuration
  network {
    id     = 0
    model  = "virtio"
    bridge = var.network_bridge
  }
  
  # Cloud-init configuration
  os_type = "cloud-init"
  
  sshkeys = <<EOF
${var.ssh_public_key}
EOF
  
  # Static IP assignment
  ipconfig0 = "ip=${var.worker_ips[count.index]}/24,gw=${var.gateway}"
  
  nameserver = join(" ", var.dns_servers)
  
  # Boot settings
  boot = "order=scsi0"
  
  # QEMU agent
  agent = 1
  
  # Tags for identification
  tags = join(";", [
    "k3s",
    "worker",
    var.environment
  ])
  
  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }
}
