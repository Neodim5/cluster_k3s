# Proxmox VE Terraform Module

module "proxmox_k3s" {
  source = "../../modules/proxmox"

  # Cluster configuration
  environment   = var.environment
  template      = var.template
  
  # Proxmox connection
  proxmox_api_url    = var.proxmox_api_url
  proxmox_api_token  = var.proxmox_api_token
  
  # VM Template and storage
  vm_template_id = var.vm_template_id
  storage        = var.storage
  network_bridge = var.network_bridge
  proxmox_node   = var.proxmox_node
  
  # Node counts from template variables
  master_count = var.master_count
  worker_count = var.worker_count
  
  # VM resources configuration
  master_config = var.master_config
  worker_config = var.worker_config
  
  # Network configuration - extract IPs from subnet
  gateway     = var.network_config.gateway
  dns_servers = var.network_config.dns_servers
  
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

output "all_nodes" {
  description = "All nodes with roles"
  value       = module.proxmox_k3s.all_nodes
}
