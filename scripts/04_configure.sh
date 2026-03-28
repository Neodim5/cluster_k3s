#!/usr/bin/env bash

# Post-installation Configuration Script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"

ENVIRONMENT="${ENVIRONMENT:-dev}"

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
            *) log_error "Unknown option: $1"; exit 1 ;;
        esac
    done
}

configure_cluster() {
    local inventory_file="$ANSIBLE_DIR/inventory/${ENVIRONMENT}_hosts.ini"
    
    log_info "Configuring K3S cluster..."
    
    cd "$ANSIBLE_DIR"
    
    ansible-playbook playbooks/configure_cluster.yml \
        -i "$inventory_file" \
        --become
}

verify_cluster() {
    log_info "Verifying cluster health..."
    
    # Wait for nodes to be ready
    sleep 10
    
    if ! kubectl wait --for=condition=ready nodes --all --timeout=120s; then
        log_error "Some nodes are not ready!"
        exit 1
    fi
    
    # Check system pods
    if ! kubectl wait --for=condition=ready pods -n kube-system --all --timeout=300s; then
        log_error "Some system pods are not ready!"
        exit 1
    fi
    
    log_info "Cluster verification completed successfully!"
    kubectl get nodes -o wide
    kubectl get pods -n kube-system
}

install_addons() {
    log_info "Installing cluster addons..."
    
    cd "$ANSIBLE_DIR"
    
    ansible-playbook playbooks/install_addons.yml \
        -i "$ANSIBLE_DIR/inventory/${ENVIRONMENT}_hosts.ini" \
        --become
}

main() {
    parse_args "$@"
    
    log_info "=== Post-installation Configuration ==="
    log_info "Environment: $ENVIRONMENT"
    
    configure_cluster
    verify_cluster
    install_addons
    
    log_info "Cluster configuration completed!"
    log_info "You can now access your cluster with: kubectl --context k3s-${ENVIRONMENT}"
}

main "$@"
