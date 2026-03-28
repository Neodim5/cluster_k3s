# Environment variables
variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  default     = "dev"
}

# Template configuration
variable "template" {
  description = "Deployment template (simple, middle, custom)"
  type        = string
  default     = "simple"
  
  validation {
    condition     = contains(["simple", "middle", "custom"], var.template)
    error_message = "Template must be one of: simple, middle, custom."
  }
}

# Proxmox connection
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API Token (format: user@realm!tokenid=secret)"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name where VMs will be created"
  type        = string
  default     = "pve"
}

# VM Configuration
variable "vm_template_id" {
  description = "Proxmox VM template ID to clone from"
  type        = number
}

variable "storage" {
  description = "Proxmox storage name (e.g., local-lvm, ceph-pool)"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Proxmox network bridge (e.g., vmbr0)"
  type        = string
  default     = "vmbr0"
}

# SSH Configuration
variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

# Node counts from template
variable "master_count" {
  description = "Number of master nodes (from template)"
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Number of worker nodes (from template)"
  type        = number
  default     = 2
}

# Master node configuration
variable "master_config" {
  description = "Master node VM configuration"
  type = object({
    cpu_cores = number
    memory_gb = number
    disk_gb   = number
  })
  
  default = {
    cpu_cores = 2
    memory_gb = 4
    disk_gb   = 50
  }
}

# Worker node configuration
variable "worker_config" {
  description = "Worker node VM configuration"
  type = object({
    cpu_cores = number
    memory_gb = number
    disk_gb   = number
  })
  
  default = {
    cpu_cores = 2
    memory_gb = 4
    disk_gb   = 50
  }
}

# Network configuration
variable "network_config" {
  description = "Network configuration for VMs"
  type = object({
    subnet      = string
    gateway     = string
    dns_servers = list(string)
  })
  
  default = {
    subnet      = "192.168.1.0/24"
    gateway     = "192.168.1.1"
    dns_servers = ["8.8.8.8", "8.8.4.4"]
  }
}
