# K3S Installer - Main Entry Point

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
ENVIRONMENT="${ENVIRONMENT:-dev}"
TEMPLATE="${TEMPLATE:-simple}"
CLOUD_PROVIDER="${CLOUD_PROVIDER:-proxmox}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local deps=("terraform" "ansible" "kubectl")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "$dep is not installed. Please install it first."
            exit 1
        fi
    done
    
    # Check for k3sup (optional)
    if ! command -v k3sup &> /dev/null; then
        log_warn "k3sup is not installed. Will use ansible for k3s installation."
        export USE_K3SUP="false"
    else
        export USE_K3SUP="true"
    fi
    
    log_info "All prerequisites checked."
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -t|--template)
                TEMPLATE="$2"
                shift 2
                ;;
            -c|--cloud)
                CLOUD_PROVIDER="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
K3S Cluster Installer

Usage: $(basename "$0") [OPTIONS]

Options:
    -e, --environment ENV     Environment name (dev, prod). Default: dev
    -t, --template TEMPLATE   Deployment template (simple, middle, custom). Default: simple
    -c, --cloud PROVIDER      Cloud provider (proxmox, yandex). Default: proxmox
    -h, --help                Show this help message

Examples:
    $(basename "$0") -e dev -t simple -c proxmox
    $(basename "$0") --environment prod --template middle --cloud yandex

Environment Variables:
    ENVIRONMENT       Same as -e option
    TEMPLATE          Same as -t option
    CLOUD_PROVIDER    Same as -c option
EOF
}

# Main execution
main() {
    parse_args "$@"
    
    log_info "Starting K3S Cluster Installation"
    log_info "Environment: $ENVIRONMENT"
    log_info "Template: $TEMPLATE"
    log_info "Cloud Provider: $CLOUD_PROVIDER"
    
    check_prerequisites
    
    # Step 1: Infrastructure provisioning with Terraform
    log_info "Step 1: Provisioning infrastructure..."
    bash "$SCRIPT_DIR/01_terraform.sh" \
        -e "$ENVIRONMENT" \
        -c "$CLOUD_PROVIDER" \
        -t "$TEMPLATE"
    
    # Step 2: Host preparation with Ansible
    log_info "Step 2: Preparing hosts..."
    bash "$SCRIPT_DIR/02_ansible_prepare.sh" \
        -e "$ENVIRONMENT" \
        -c "$CLOUD_PROVIDER"
    
    # Step 3: K3S installation
    log_info "Step 3: Installing K3S cluster..."
    if [[ "$USE_K3SUP" == "true" ]]; then
        bash "$SCRIPT_DIR/03_k3sup_install.sh" \
            -e "$ENVIRONMENT" \
            -t "$TEMPLATE"
    else
        bash "$SCRIPT_DIR/03_ansible_k3s.sh" \
            -e "$ENVIRONMENT" \
            -t "$TEMPLATE"
    fi
    
    # Step 4: Post-installation configuration
    log_info "Step 4: Configuring cluster..."
    bash "$SCRIPT_DIR/04_configure.sh" \
        -e "$ENVIRONMENT"
    
    log_info "K3S Cluster installation completed successfully!"
}

main "$@"
