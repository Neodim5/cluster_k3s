# K3S Cluster Installation - Quick Start Guide

## Prerequisites

### Required Software
- **Terraform** >= 1.5.0
- **Ansible** >= 2.10.0
- **kubectl** (for cluster management)
- **k3sup** (optional, for alternative installation method)

### Infrastructure Requirements

#### Proxmox VE
- Proxmox VE 7.x or 8.x cluster
- VM template with Ubuntu 22.04 LTS (cloud-init enabled)
- API token with sufficient permissions
- Network bridge configured

#### Yandex Cloud
- Yandex Cloud account with active billing
- Service account with appropriate IAM roles
- Folder ID for resource deployment

## Installation

### 1. Clone and Setup

```bash
cd /workspace
```

### 2. Configure Environment

Create environment-specific configuration:

```bash
# Copy example configuration
cp terraform/environments/dev/proxmox.tfvars.example terraform/environments/dev/proxmox.tfvars

# Edit configuration
vim terraform/environments/dev/proxmox.tfvars
```

### 3. Deploy Cluster

#### Using the main installer script (recommended):

```bash
# Simple cluster (1 master + workers)
./scripts/install.sh -e dev -t simple -c proxmox

# HA cluster (3 masters + workers)
./scripts/install.sh -e dev -t middle -c proxmox

# Custom configuration
./scripts/install.sh -e dev -t custom -c proxmox \
  --extra-vars "masters_count=3 workers_count=5"
```

#### Or run steps manually:

```bash
# Step 1: Provision infrastructure
./scripts/01_terraform.sh -e dev -c proxmox -t simple

# Step 2: Prepare hosts
./scripts/02_ansible_prepare.sh -e dev -c proxmox

# Step 3a: Install K3S with Ansible
./scripts/03_ansible_k3s.sh -e dev -t simple

# OR Step 3b: Install K3S with k3sup
./scripts/03_k3sup_install.sh -e dev -t simple

# Step 4: Configure cluster
./scripts/04_configure.sh -e dev
```

## Templates

### Simple (1 Master)
- Single control plane node
- Suitable for development/testing
- Workers can be added as needed

```bash
./scripts/install.sh -t simple -e dev
```

### Middle (3 Masters - HA)
- High availability setup
- Embedded etcd datastore
- Recommended for production

```bash
./scripts/install.sh -t middle -e dev
```

### Custom
- Fully configurable
- Specify exact number of masters and workers
- Custom network settings

```bash
./scripts/install.sh -t custom -e dev \
  --extra-vars "masters_count=5 workers_count=10"
```

## Verification

After installation, verify the cluster:

```bash
# Check nodes
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# Test cluster info
kubectl cluster-info
```

## Accessing the Cluster

Kubeconfig is automatically merged to `~/.kube/config`:

```bash
# Use the context
kubectl config use-context k3s-dev

# Or specify context per command
kubectl --context k3s-dev get nodes
```

## Troubleshooting

### Common Issues

1. **VMs not starting**
   - Check Proxmox/Yandex credentials
   - Verify VM template exists
   - Check resource quotas

2. **SSH connection failures**
   - Verify SSH key is added to VM template
   - Check network connectivity
   - Ensure security groups allow SSH

3. **K3S installation fails**
   - Check system requirements (swap disabled, kernel modules)
   - Review logs: `journalctl -u k3s`
   - Verify network connectivity between nodes

### Logs Location

- Ansible logs: `ansible/ansible.log`
- Terraform state: `terraform/environments/<env>/terraform.tfstate`
- K3S logs: `/var/log/k3s.log` on nodes

## Cleanup

To destroy the cluster:

```bash
cd terraform/environments/dev
terraform destroy -var-file=proxmox.tfvars
```

## Next Steps

1. Install additional addons (monitoring, logging, etc.)
2. Configure ingress controller
3. Deploy your applications
4. Set up backup solutions
5. Configure monitoring and alerting

## Support

For issues and feature requests, please refer to the project documentation or open an issue.
