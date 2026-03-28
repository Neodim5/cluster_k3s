variable "environment" {
  description = "Environment name"
  type        = string
}

variable "template" {
  description = "Deployment template"
  type        = string
}

variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API Token"
  type        = string
  sensitive   = true
}

variable "vm_template_id" {
  description = "VM template ID to clone from"
  type        = number
}

variable "storage" {
  description = "Proxmox storage name"
  type        = string
}

variable "network_bridge" {
  description = "Proxmox network bridge"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "master_count" {
  description = "Number of master nodes"
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 1
}

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

variable "master_ips" {
  description = "List of static IPs for master nodes"
  type        = list(string)
  default     = []
}

variable "worker_ips" {
  description = "List of static IPs for worker nodes"
  type        = list(string)
  default     = []
}

variable "gateway" {
  description = "Network gateway"
  type        = string
  default     = "192.168.1.1"
}

variable "dns_servers" {
  description = "DNS servers"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "create_template" {
  description = "Create base template"
  type        = bool
  default     = false
}

variable "base_image" {
  description = "Base image to clone for template"
  type        = string
  default     = "ubuntu-22.04-cloud-init"
}

variable "temp_password" {
  description = "Temporary password for template creation"
  type        = string
  default     = "ChangeMe123!"
  sensitive   = true
}
