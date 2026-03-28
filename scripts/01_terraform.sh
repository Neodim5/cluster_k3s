#!/usr/bin/env bash

# Terraform Infrastructure Provisioning Script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

ENVIRONMENT="${ENVIRONMENT:-dev}"
CLOUD_PROVIDER="${CLOUD_PROVIDER:-proxmox}"
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
            -c|--cloud) CLOUD_PROVIDER="$2"; shift 2 ;;
            -t|--template) TEMPLATE="$2"; shift 2 ;;
            *) log_error "Unknown option: $1"; exit 1 ;;
        esac
    done
}

validate_config() {
    local env_file="$TERRAFORM_DIR/environments/$ENVIRONMENT/${CLOUD_PROVIDER}.tfvars"
    
    if [[ ! -f "$env_file" ]]; then
        log_error "Environment config not found: $env_file"
        exit 1
    fi
    
    if [[ ! -d "$TERRAFORM_DIR/modules/$CLOUD_PROVIDER" ]]; then
        log_error "Terraform module not found for provider: $CLOUD_PROVIDER"
        exit 1
    fi
}

init_terraform() {
    local workdir="$TERRAFORM_DIR/environments/$ENVIRONMENT"
    
    log_info "Initializing Terraform in $workdir..."
    cd "$workdir"
    
    if [[ ! -d ".terraform" ]]; then
        terraform init \
            -backend-config="path=$workdir/terraform.tfstate"
    fi
}

plan_infrastructure() {
    local workdir="$TERRAFORM_DIR/environments/$ENVIRONMENT"
    local var_file="$workdir/${CLOUD_PROVIDER}.tfvars"
    
    log_info "Planning infrastructure..."
    cd "$workdir"
    
    terraform plan \
        -var-file="$var_file" \
        -var="template=$TEMPLATE" \
        -out=tfplan
}

apply_infrastructure() {
    local workdir="$TERRAFORM_DIR/environments/$ENVIRONMENT"
    
    log_info "Applying infrastructure..."
    cd "$workdir"
    
    terraform apply -auto-approve tfplan
    
    # Export outputs for Ansible
    log_info "Exporting infrastructure outputs..."
    terraform output -json > "$PROJECT_ROOT/ansible/inventory/${ENVIRONMENT}_${CLOUD_PROVIDER}_hosts.json"
}

main() {
    parse_args "$@"
    
    log_info "=== Terraform Infrastructure Provisioning ==="
    log_info "Environment: $ENVIRONMENT"
    log_info "Cloud Provider: $CLOUD_PROVIDER"
    log_info "Template: $TEMPLATE"
    
    validate_config
    init_terraform
    plan_infrastructure
    apply_infrastructure
    
    log_info "Infrastructure provisioning completed!"
}

main "$@"
