# Proxmox VE Terraform Module

module "proxmox_k3s" {
  source = "../../modules/proxmox"

  # Cluster configuration
  template      = var.template
  environment   = var.environment
  
  # Proxmox connection
  proxmox_api_url    = var.proxmox_api_url
  proxmox_api_token  = var.proxmox_api_token
  
  # Node configuration
  master_nodes = var.master_nodes
  worker_nodes = var.worker_nodes
  
  # VM settings
  vm_template_id = var.vm_template_id
  storage        = var.storage
  network_bridge = var.network_bridge
  
  # SSH configuration
  ssh_public_key = var.ssh_public_key
  
  tags = [
    "k3s",
    "cluster-${var.environment}",
    "managed-by-terraform"
  ]
}

# Outputs
output "master_nodes" {
  description = "List of master node information"
  value       = module.proxmox_k3s.master_nodes
}

output "worker_nodes" {
  description = "List of worker node information"
  value       = module.proxmox_k3s.worker_nodes
}

output "cluster_endpoint" {
  description = "K3S cluster endpoint"
  value       = module.proxmox_k3s.cluster_endpoint
}
