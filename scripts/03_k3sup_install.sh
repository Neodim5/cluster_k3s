#!/usr/bin/env bash

# K3S Installation via k3sup Script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"

ENVIRONMENT="${ENVIRONMENT:-dev}"
TEMPLATE="${TEMPLATE:-simple}"
K3S_VERSION="${K3S_VERSION:-v1.28.5+k3s1}"
SSH_USER="${SSH_USER:-root}"
SSH_KEY="${SSH_KEY:-~/.ssh/id_rsa}"

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
            -t|--template) TEMPLATE="$2"; shift 2 ;;
            *) log_error "Unknown option: $1"; exit 1 ;;
        esac
    done
}

get_node_ips() {
    local inventory_file="$ANSIBLE_DIR/inventory/${ENVIRONMENT}_hosts.ini"
    
    if [[ ! -f "$inventory_file" ]]; then
        log_error "Inventory file not found: $inventory_file"
        exit 1
    fi
    
    # Extract master IPs
    MASTER_IP=$(grep -A1 "\[masters\]" "$inventory_file" | tail -1 | awk '{print $2}' | cut -d'=' -f2)
    
    # Extract worker IPs
    WORKER_IPS=$(grep -A10 "\[workers\]" "$inventory_file" | grep ansible_host | awk '{print $2}' | cut -d'=' -f2)
    
    export MASTER_IP
    export WORKER_IPS
}

install_k3s_server() {
    log_info "Installing K3S server on master node: $MASTER_IP"
    
    local k3sup_cmd="k3sup install \
        --ip $MASTER_IP \
        --user $SSH_USER \
        --k3s-version $K3S_VERSION \
        --ssh-key $SSH_KEY"
    
    # Add template-specific flags
    case "$TEMPLATE" in
        simple|middle)
            # Default single or HA setup
            ;;
        custom)
            # Custom configuration loaded from template
            ;;
    esac
    
    log_info "Executing: $k3sup_cmd"
    eval "$k3sup_cmd"
}

join_agents() {
    if [[ -z "$WORKER_IPS" ]]; then
        log_info "No worker nodes to join."
        return
    fi
    
    log_info "Joining worker nodes to cluster..."
    
    for worker_ip in $WORKER_IPS; do
        log_info "Joining worker: $worker_ip"
        
        k3sup join \
            --ip "$worker_ip" \
            --server-ip "$MASTER_IP" \
            --user "$SSH_USER" \
            --ssh-key "$SSH_KEY" \
            --k3s-version "$K3S_VERSION"
    done
}

merge_kubeconfig() {
    log_info "Merging kubeconfig..."
    
    k3sup merge \
        --path ./kubeconfig \
        --local-path $HOME/.kube/config \
        --context k3s-${ENVIRONMENT}
    
    log_info "Kubeconfig saved to $HOME/.kube/config with context: k3s-${ENVIRONMENT}"
}

main() {
    parse_args "$@"
    
    log_info "=== K3S Installation (k3sup) ==="
    log_info "Environment: $ENVIRONMENT"
    log_info "Template: $TEMPLATE"
    log_info "K3S Version: $K3S_VERSION"
    
    get_node_ips
    install_k3s_server
    join_agents
    merge_kubeconfig
    
    log_info "K3S installation completed with k3sup!"
}

main "$@"
