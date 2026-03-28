#!/usr/bin/env bash

# K3S Installation via Ansible Script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"

ENVIRONMENT="${ENVIRONMENT:-dev}"
TEMPLATE="${TEMPLATE:-simple}"

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

load_template_config() {
    local template_file="$PROJECT_ROOT/templates/${TEMPLATE}.yml"
    
    if [[ -f "$template_file" ]]; then
        log_info "Loading template configuration: $TEMPLATE"
        export ANSIBLE_EXTRA_VARS="@$template_file"
    else
        log_warn "Template file not found: $template_file. Using defaults."
        export ANSIBLE_EXTRA_VARS=""
    fi
}

install_k3s() {
    local inventory_file="$ANSIBLE_DIR/inventory/${ENVIRONMENT}_hosts.ini"
    
    log_info "Installing K3S with Ansible..."
    log_info "Template: $TEMPLATE"
    
    cd "$ANSIBLE_DIR"
    
    if [[ -n "$ANSIBLE_EXTRA_VARS" ]]; then
        ansible-playbook playbooks/install_k3s.yml \
            -i "$inventory_file" \
            -e "$ANSIBLE_EXTRA_VARS" \
            --become
    else
        ansible-playbook playbooks/install_k3s.yml \
            -i "$inventory_file" \
            -e "template=$TEMPLATE" \
            --become
    fi
}

main() {
    parse_args "$@"
    
    log_info "=== K3S Installation (Ansible) ==="
    log_info "Environment: $ENVIRONMENT"
    log_info "Template: $TEMPLATE"
    
    load_template_config
    install_k3s
    
    log_info "K3S installation completed!"
}

main "$@"
