variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  nullable    = false
}

variable "folder_id" {
  description = "Yandex Folder ID where resources will be created"
  type        = string
  nullable    = false
}

variable "zone" {
  description = "Availability zone (e.g., ru-central1-a)"
  type        = string
  default     = "ru-central1-a"
}

variable "vm_prefix" {
  description = "Prefix for VM names"
  type        = string
  default     = "k3s"
}

variable "master_count" {
  description = "Number of master nodes to create"
  type        = number
  default     = 1
  validation {
    condition     = var.master_count >= 0
    error_message = "Master count must be non-negative."
  }
}

variable "worker_count" {
  description = "Number of worker nodes to create"
  type        = number
  default     = 0
  validation {
    condition     = var.worker_count >= 0
    error_message = "Worker count must be non-negative."
  }
}

variable "platform_id" {
  description = "VM platform type (standard-v3, highfreq-v3, etc.)"
  type        = string
  default     = "standard-v3"
}

variable "cpu_cores" {
  description = "Number of CPU cores per VM"
  type        = number
  default     = 2
}

variable "memory_gb" {
  description = "Amount of memory in GB per VM"
  type        = number
  default     = 4
}

variable "disk_size_gb" {
  description = "Size of the boot disk in GB"
  type        = number
  default     = 30
}

variable "disk_type" {
  description = "Type of boot disk (network-hdd, network-ssd, network-ssd-nonreplicated)"
  type        = string
  default     = "network-hdd"
}

variable "image_family" {
  description = "OS image family name"
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "subnet_id" {
  description = "Subnet ID for network interface"
  type        = string
  nullable    = false
}

variable "external_ip" {
  description = "Assign external/public IP address to VMs"
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "SSH public key for user-data configuration"
  type        = string
  nullable    = false
}

variable "user" {
  description = "Username for SSH access"
  type        = string
  default     = "ubuntu"
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to VMs"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to VMs as key-value pairs"
  type        = map(string)
  default     = {}
}

# Data source for latest Ubuntu image
data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}

# Local values for node naming
locals {
  master_names = [
    for i in range(var.master_count) : 
    "${var.vm_prefix}-master-${i + 1}"
  ]
  
  worker_names = [
    for i in range(var.worker_count) : 
    "${var.vm_prefix}-worker-${i + 1}"
  ]
  
  # Common user-data script
  common_userdata = <<-EOF
#!/bin/bash
set -e
# Update system
apt-get update
apt-get upgrade -y

# Install essential packages
apt-get install -y \
    curl \
    wget \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    python3 \
    python3-pip \
    jq \
    vim \
    htop \
    net-tools

# Configure kernel parameters for Kubernetes
cat >> /etc/sysctl.d/k8s.conf << 'SYSCTL'
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
SYSCTL

sysctl --system

# Disable swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "Base setup completed"
EOF
}
