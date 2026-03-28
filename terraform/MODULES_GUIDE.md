# Terraform Modules Implementation Guide

## Overview
This document describes the implemented Terraform modules for deploying K3S clusters on Proxmox VE and Yandex Cloud.

## Module Structure

```
terraform/
├── modules/
│   ├── proxmox/          # Proxmox VE module
│   │   ├── README.md     # Module documentation
│   │   ├── variables.tf  # Input variables
│   │   ├── nodes.tf      # VM resources (masters & workers)
│   │   ├── template.tf   # Base template creation (optional)
│   │   └── outputs.tf    # Output values
│   └── yandex/           # Yandex Cloud module
│       ├── README.md     # Module documentation
│       ├── variables.tf  # Input variables
│       ├── nodes.tf      # Compute instances (masters & workers)
│       └── outputs.tf    # Output values
├── environments/
│   ├── dev/              # Development environment
│   │   ├── main.tf       # Root module configuration
│   │   ├── variables.tf  # Environment variables
│   │   ├── providers.tf  # Provider configuration
│   │   ├── proxmox.tfvars.example  # Example config
│   │   └── templates/    # Deployment templates
│   └── prod/             # Production environment
└── templates/            # Global templates
```

## Proxmox Module (`modules/proxmox/`)

### Features
- Creates master and worker VMs from a cloud-init template
- Automatic IP assignment from specified range
- SSH key injection via cloud-init
- Configurable CPU, memory, and disk resources
- Support for multiple node counts based on templates

### Key Files

#### `variables.tf`
Defines all input variables:
- `proxmox_api_url`, `proxmox_api_token` - API connection
- `vm_template_id` - Source template ID
- `master_count`, `worker_count` - Node counts
- `master_config`, `worker_config` - Resource configurations
- `network_bridge`, `storage` - Infrastructure settings
- `ssh_public_key` - SSH access key
- `gateway`, `dns_servers` - Network configuration

#### `nodes.tf`
Creates VM resources:
- `proxmox_vm_qemu.masters` - Master node VMs
- `proxmox_vm_qemu.workers` - Worker node VMs
- Cloud-init configuration for each VM
- Static IP assignment based on `ip_range_start`

#### `outputs.tf`
Exports cluster information:
- `master_nodes` - List of master node details
- `worker_nodes` - List of worker node details
- `all_nodes` - Combined list with roles
- `cluster_endpoint` - K3S API endpoint

### Usage Example

```hcl
module "proxmox_k3s" {
  source = "../../modules/proxmox"

  # Connection
  proxmox_api_url   = "https://192.168.1.100:8006/api2/json"
  proxmox_api_token = "root@pam!terraform=secret"
  proxmox_node      = "pve"

  # Template
  vm_template_id = 9000
  storage        = "local-lvm"
  network_bridge = "vmbr0"

  # Nodes
  master_count = 1
  worker_count = 2

  # Resources
  master_config = {
    cpu_cores = 2
    memory_gb = 4
    disk_gb   = 50
  }

  worker_config = {
    cpu_cores = 2
    memory_gb = 4
    disk_gb   = 50
  }

  # Network
  gateway     = "192.168.1.1"
  dns_servers = ["8.8.8.8", "8.8.4.4"]

  # SSH
  ssh_public_key = file("~/.ssh/id_rsa.pub")
}
```

## Yandex Cloud Module (`modules/yandex/`)

### Features
- Creates compute instances from Ubuntu LTS images
- User-data for automatic configuration
- External IP support (optional)
- Security group integration
- Automatic kernel tuning for Kubernetes

### Key Files

#### `variables.tf`
Defines input variables:
- `cloud_id`, `folder_id` - Yandex Cloud identifiers
- `zone` - Availability zone
- `subnet_id` - Network subnet
- `master_count`, `worker_count` - Node counts
- `platform_id` - VM platform type
- `external_ip` - Public IP assignment
- `security_group_ids` - Network security

#### `nodes.tf`
Creates compute instances:
- `yandex_compute_instance.masters` - Master nodes
- `yandex_compute_instance.workers` - Worker nodes
- Cloud-init user-data for setup
- Kernel parameter tuning
- Swap disablement

#### `outputs.tf`
Exports cluster information:
- `master_nodes`, `worker_nodes` - Node details
- `all_nodes` - Combined list
- `cluster_endpoint` - API endpoint
- `inventory_hosts` - Ansible inventory format

### Usage Example

```hcl
module "yandex_k3s" {
  source = "../../modules/yandex"

  # Cloud settings
  cloud_id  = "b1gxxxxxxxxxxxxx"
  folder_id = "b1hxxxxxxxxxxxxx"
  zone      = "ru-central1-a"

  # Network
  subnet_id = "e9bxxxxxxxxxxxxx"
  external_ip = true

  # Nodes
  master_count = 3
  worker_count = 2

  # Resources
  cpu_cores  = 4
  memory_gb  = 8
  disk_size_gb = 50

  # SSH
  ssh_public_key = file("~/.ssh/id_rsa.pub")
}
```

## Deployment Templates

### Simple Template (`templates/simple.tfvars`)
- 1 Master node
- Configurable worker nodes (default: 2)
- Suitable for development/testing

### Middle Template (`templates/middle.tfvars`)
- 3 Master nodes (HA configuration)
- Configurable worker nodes (default: 3)
- Suitable for production

### Custom Template (`templates/custom.tfvars`)
- User-defined master count
- User-defined worker count
- Full flexibility

## Quick Start

### 1. Configure Proxmox

```bash
cd terraform/environments/dev
cp proxmox.tfvars.example proxmox.tfvars
```

Edit `proxmox.tfvars`:
- Set `proxmox_api_url` to your Proxmox API URL
- Set `proxmox_api_token` (format: `user@realm!tokenid=secret`)
- Set `vm_template_id` to your template VM ID
- Set `ssh_public_key` to your public key
- Adjust network settings (`gateway`, `ip_range_start`)

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan Deployment

```bash
# Simple template (1 master + 2 workers)
terraform plan -var-file="proxmox.tfvars" -var-file="templates/simple.tfvars"
```

### 4. Apply Configuration

```bash
terraform apply -var-file="proxmox.tfvars" -var-file="templates/simple.tfvars"
```

### 5. Get Cluster Information

```bash
terraform output -json all_nodes
terraform output cluster_endpoint
```

## Outputs Reference

After deployment, use these outputs:

```bash
# All nodes with IPs and roles
terraform output all_nodes

# Master nodes only
terraform output master_nodes

# Worker nodes only
terraform output worker_nodes

# K3S API endpoint
terraform output cluster_endpoint

# Ansible inventory
terraform output inventory_hosts
```

## Troubleshooting

### Common Issues

1. **API Token Error**
   - Ensure token format is correct: `user@realm!tokenid=secret`
   - Verify token has sufficient permissions in Proxmox

2. **Template Not Found**
   - Create VM template before running Terraform
   - Verify `vm_template_id` exists in Proxmox

3. **Network Issues**
   - Check `network_bridge` name matches your Proxmox configuration
   - Ensure `ip_range_start` is in correct subnet

4. **SSH Connection Failed**
   - Verify SSH public key is correctly formatted
   - Check cloud-init is installed in template VM

## Next Steps

After Terraform deployment:
1. Run Ansible playbooks for K3S installation
2. Or use k3sup for quick cluster setup
3. Configure kubectl access
4. Deploy applications

See `docs/setup_guide.md` for detailed instructions.
