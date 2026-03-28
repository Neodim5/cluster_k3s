#!/usr/bin/env bash

# Ansible Host Preparation Script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"

ENVIRONMENT="${ENVIRONMENT:-dev}"
CLOUD_PROVIDER="${CLOUD_PROVIDER:-proxmox}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment) ENVIRONMENT="$2"; shift 2 ;;
            -c|--cloud) CLOUD_PROVIDER="$2"; shift 2 ;;
            *) log_error "Unknown option: $1"; exit 1 ;;
        esac
    done
}

generate_inventory() {
    local inventory_file="$ANSIBLE_DIR/inventory/${ENVIRONMENT}_hosts.ini"
    local json_file="$ANSIBLE_DIR/inventory/${ENVIRONMENT}_${CLOUD_PROVIDER}_hosts.json"
    
    log_info "Generating Ansible inventory..."
    
    # Create inventory from Terraform outputs
    if [[ -f "$json_file" ]]; then
        python3 << EOF
import json

with open('$json_file', 'r') as f:
    data = json.load(f)

masters = []
workers = []

# Parse master nodes
if 'master_nodes' in data:
    for node in data['master_nodes']['value']:
        masters.append(f"{node['name']} ansible_host={node['ip']}")

# Parse worker nodes  
if 'worker_nodes' in data:
    for node in data['worker_nodes']['value']:
        workers.append(f"{node['name']} ansible_host={node['ip']}")

with open('$inventory_file', 'w') as f:
    f.write("[masters]\\n")
    for m in masters:
        f.write(f"{m}\\n")
    f.write("\\n[workers]\\n")
    for w in workers:
        f.write(f"{w}\\n")
    f.write("\\n[k3s_cluster:children]\\n")
    f.write("masters\\n")
    f.write("workers\\n")

print(f"Inventory generated: {len(masters)} masters, {len(workers)} workers")
EOF
    else
        log_warn "No Terraform output found. Using static inventory."
        cat > "$inventory_file" << EOF
[masters]
master-1 ansible_host=192.168.1.10

[workers]
worker-1 ansible_host=192.168.1.11
worker-2 ansible_host=192.168.1.12

[k3s_cluster:children]
masters
workers
EOF
    fi
}

prepare_hosts() {
    local inventory_file="$ANSIBLE_DIR/inventory/${ENVIRONMENT}_hosts.ini"
    
    log_info "Preparing hosts with Ansible..."
    
    cd "$ANSIBLE_DIR"
    
    ansible-playbook playbooks/prepare_hosts.yml \
        -i "$inventory_file" \
        -e "cloud_provider=$CLOUD_PROVIDER" \
        --become
}

main() {
    parse_args "$@"
    
    log_info "=== Ansible Host Preparation ==="
    log_info "Environment: $ENVIRONMENT"
    log_info "Cloud Provider: $CLOUD_PROVIDER"
    
    generate_inventory
    prepare_hosts
    
    log_info "Host preparation completed!"
}

main "$@"
