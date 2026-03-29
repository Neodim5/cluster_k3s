# Proxmox VM Template Configuration
# This configuration is used as a base for creating K3S nodes

# Cloud-init template for Ubuntu 22.04
resource "proxmox_vm_qemu" "k3s_template" {
  count       = var.create_template ? 1 : 0
  name        = "k3s-base-template"
  target_node = var.proxmox_node
  clone       = var.base_image
  
  # VM resources
  cores  = 2
  memory = 4096
  
  # Disk configuration
  disk {
    slot     = 0
    size     = "50G"
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
  os_type   = "cloud-init"
  cipassword = var.temp_password
  
  sshkeys = <<EOF
${var.ssh_public_key}
EOF
  
  ipconfig0 = "ip=dhcp"
  
  # Boot settings
  boot = "order=scsi0;ide2"
  
  # QEMU agent
  agent = 1
  
  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }
}

# Outputs
output "template_id" {
  value = var.create_template ? proxmox_vm_qemu.k3s_template[0].vmid : null
}
