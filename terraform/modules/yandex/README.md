# Yandex Cloud Module for K3S Cluster

## Description
This module creates Virtual Machines in Yandex Cloud for a K3S cluster using the `yandex-cloud/yandex` provider.
It supports user-data for automatic configuration of hostname, SSH keys, and network settings.

## Requirements
- Yandex Cloud account with billing enabled
- Terraform >= 1.0
- Yandex Cloud Service Account or OAuth token
- Folder ID where resources will be created

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `cloud_id` | Yandex Cloud ID | `string` | n/a | yes |
| `folder_id` | Yandex Folder ID | `string` | n/a | yes |
| `zone` | Availability zone | `string` | `"ru-central1-a"` | no |
| `vm_prefix` | Prefix for VM names | `string` | `"k3s"` | no |
| `master_count` | Number of master nodes to create | `number` | `1` | no |
| `worker_count` | Number of worker nodes to create | `number` | `0` | no |
| `platform_id` | VM platform type | `string` | `"standard-v3"` | no |
| `cpu_cores` | Number of CPU cores per VM | `number` | `2` | no |
| `memory_gb` | Amount of memory in GB per VM | `number` | `4` | no |
| `disk_size_gb` | Size of the boot disk in GB | `number` | `30` | no |
| `disk_type` | Type of boot disk | `string` | `"network-hdd"` | no |
| `image_family` | OS image family | `string` | `"ubuntu-2204-lts"` | no |
| `subnet_id` | Subnet ID for network interface | `string` | n/a | yes |
| `external_ip` | Assign external IP to VMs | `bool` | `false` | no |
| `ssh_public_key` | SSH public key for user-data | `string` | n/a | yes |
| `user` | Username for SSH access | `string` | `"ubuntu"` | no |
| `security_group_ids` | List of security group IDs | `list(string)` | `[]` | no |
| `tags` | Tags to apply to VMs | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `master_nodes` | List of maps containing master node details (name, ip, id) |
| `worker_nodes` | List of maps containing worker node details (name, ip, id) |
| `all_nodes` | Combined list of all nodes |
| `cluster_endpoint` | K3S API endpoint (first master) |
| `inventory_hosts` | Ansible inventory compatible string |

## Usage

```hcl
module "yandex_k3s" {
  source = "./modules/yandex"

  cloud_id    = "b1gxxxxxxxxxxxxx"
  folder_id   = "b1hxxxxxxxxxxxxx"
  zone        = "ru-central1-a"
  vm_prefix   = "k3s-prod"
  
  master_count = 3
  worker_count = 2
  
  cpu_cores    = 4
  memory_gb    = 8
  disk_size_gb = 50
  
  subnet_id      = "e9bxxxxxxxxxxxxx"
  external_ip    = true
  ssh_public_key = file("~/.ssh/id_rsa.pub")
}

output "cluster_nodes" {
  value = module.yandex_k3s.all_nodes
}

output "api_endpoint" {
  value = module.yandex_k3s.cluster_endpoint
}
```

## User-Data Configuration
The module automatically configures each VM with:
- Hostname matching the node role and index
- SSH authorized keys
- User creation
- Network configuration via DHCP

## Network Requirements
- Subnet must have available IP addresses
- Security groups should allow:
  - SSH (22/tcp) from trusted IPs
  - K3S API (6443/tcp) from workers and admins
  - Inter-node communication (all traffic within cluster)

## Notes
- External IPs are optional and incur additional costs
- Use private networking with bastion host for production
- Ensure service account has compute.instanceAdmin permissions
- Boot disk images are automatically selected from latest LTS Ubuntu
