#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          K3S Cluster Installer - Setup Script            ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
ENVIRONMENT="dev"
CLOUD_PROVIDER="proxmox"
TEMPLATE="simple"
ACTION="all"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -c|--cloud)
            CLOUD_PROVIDER="$2"
            shift 2
            ;;
        -t|--template)
            TEMPLATE="$2"
            shift 2
            ;;
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -e, --environment ENV    Environment name (default: dev)"
            echo "  -c, --cloud PROVIDER     Cloud provider: proxmox, yandex (default: proxmox)"
            echo "  -t, --template TEMPLATE  Cluster template: simple, middle, custom (default: simple)"
            echo "  -a, --action ACTION      Action to perform: check, setup, all (default: all)"
            echo "                           check - only check dependencies"
            echo "                           setup - copy configs and prepare"
            echo "                           all - check + setup + init terraform"
            echo "  -h, --help               Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                              # Run full setup with defaults"
            echo "  $0 -e dev -t simple             # Dev environment, simple template"
            echo "  $0 -c yandex -t middle          # Yandex Cloud, HA cluster"
            echo "  $0 -a check                     # Only check dependencies"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

echo -e "${YELLOW}Configuration:${NC}"
echo "  Environment: ${BLUE}$ENVIRONMENT${NC}"
echo "  Cloud Provider: ${BLUE}$CLOUD_PROVIDER${NC}"
echo "  Template: ${BLUE}$TEMPLATE${NC}"
echo "  Action: ${BLUE}$ACTION${NC}"
echo ""

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" == "ok" ]; then
        echo -e "${GREEN}✓${NC} $message"
    elif [ "$status" == "warning" ]; then
        echo -e "${YELLOW}⚠${NC} $message"
    elif [ "$status" == "error" ]; then
        echo -e "${RED}✗${NC} $message"
    elif [ "$status" == "info" ]; then
        echo -e "${BLUE}ℹ${NC} $message"
    fi
}

# Step 1: Check dependencies
if [[ "$ACTION" == "check" || "$ACTION" == "all" ]]; then
    echo -e "${YELLOW}Step 1: Checking dependencies...${NC}"
    echo ""
    
    if [ -x "$SCRIPT_DIR/check_dependencies.sh" ]; then
        if ! "$SCRIPT_DIR/check_dependencies.sh"; then
            echo ""
            echo -e "${RED}Dependency check failed. Please install missing dependencies first.${NC}"
            exit 1
        fi
    else
        print_status "warning" "check_dependencies.sh not found, skipping detailed check"
        
        # Basic checks
        if ! command -v terraform >/dev/null 2>&1; then
            print_status "error" "Terraform is not installed"
            exit 1
        fi
        
        if ! command -v ansible >/dev/null 2>&1; then
            print_status "error" "Ansible is not installed"
            exit 1
        fi
        
        print_status "ok" "Basic dependencies check passed"
    fi
    
    echo ""
fi

# Step 2: Setup configuration files
if [[ "$ACTION" == "setup" || "$ACTION" == "all" ]]; then
    echo -e "${YELLOW}Step 2: Setting up configuration files...${NC}"
    echo ""
    
    CONFIG_DIR="$PROJECT_ROOT/terraform/environments/$ENVIRONMENT"
    
    # Create environment directory if it doesn't exist
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        print_status "ok" "Created environment directory: $CONFIG_DIR"
    fi
    
    # Copy configuration files based on cloud provider
    if [ "$CLOUD_PROVIDER" == "proxmox" ]; then
        EXAMPLE_FILE="$CONFIG_DIR/proxmox.tfvars.example"
        TARGET_FILE="$CONFIG_DIR/proxmox.tfvars"
        
        if [ -f "$EXAMPLE_FILE" ]; then
            if [ ! -f "$TARGET_FILE" ]; then
                cp "$EXAMPLE_FILE" "$TARGET_FILE"
                print_status "ok" "Copied proxmox.tfvars.example to proxmox.tfvars"
                echo -e "   ${YELLOW}Please edit $TARGET_FILE with your Proxmox settings${NC}"
            else
                print_status "info" "proxmox.tfvars already exists"
            fi
        else
            # Try root terraform directory
            if [ -f "$PROJECT_ROOT/terraform/proxmox.tfvars" ]; then
                print_status "info" "Using existing proxmox.tfvars from terraform/"
            else
                print_status "error" "Proxmox configuration example not found"
                exit 1
            fi
        fi
        
    elif [ "$CLOUD_PROVIDER" == "yandex" ]; then
        EXAMPLE_FILE="$CONFIG_DIR/yandex.tfvars.example"
        TARGET_FILE="$CONFIG_DIR/yandex.tfvars"
        
        if [ -f "$PROJECT_ROOT/terraform/yandex.tfvars" ]; then
            if [ ! -f "$TARGET_FILE" ]; then
                cp "$PROJECT_ROOT/terraform/yandex.tfvars" "$TARGET_FILE"
                print_status "ok" "Copied yandex.tfvars to environment directory"
                echo -e "   ${YELLOW}Please edit $TARGET_FILE with your Yandex Cloud settings${NC}"
            else
                print_status "info" "yandex.tfvars already exists"
            fi
        else
            print_status "error" "Yandex Cloud configuration not found"
            exit 1
        fi
    else
        print_status "error" "Unknown cloud provider: $CLOUD_PROVIDER"
        exit 1
    fi
    
    # Check template file
    TEMPLATE_FILE="$PROJECT_ROOT/terraform/templates/${TEMPLATE}.tfvars"
    if [ -f "$TEMPLATE_FILE" ]; then
        print_status "ok" "Template '${TEMPLATE}' found: $TEMPLATE_FILE"
    else
        print_status "error" "Template '${TEMPLATE}' not found"
        exit 1
    fi
    
    echo ""
fi

# Step 3: Initialize Terraform
if [[ "$ACTION" == "all" ]]; then
    echo -e "${YELLOW}Step 3: Initializing Terraform...${NC}"
    echo ""
    
    cd "$PROJECT_ROOT/terraform"
    
    if [ -d ".terraform" ]; then
        print_status "info" "Terraform already initialized, reinitializing..."
        rm -rf .terraform
        rm -f .terraform.lock.hcl
    fi
    
    if terraform init; then
        print_status "ok" "Terraform initialized successfully"
    else
        print_status "error" "Terraform initialization failed"
        exit 1
    fi
    
    echo ""
    
    # Validate configuration
    echo -e "${YELLOW}Validating Terraform configuration...${NC}"
    if terraform validate; then
        print_status "ok" "Terraform configuration is valid"
    else
        print_status "warning" "Terraform validation failed (may need configuration adjustments)"
    fi
    
    echo ""
fi

# Summary
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Setup Complete!                        ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$CLOUD_PROVIDER" == "proxmox" ]; then
    CONFIG_FILE="$PROJECT_ROOT/terraform/environments/$ENVIRONMENT/proxmox.tfvars"
else
    CONFIG_FILE="$PROJECT_ROOT/terraform/environments/$ENVIRONMENT/yandex.tfvars"
fi

TEMPLATE_FILE="$PROJECT_ROOT/terraform/templates/${TEMPLATE}.tfvars"

echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. ${YELLOW}Edit configuration file:${NC}"
echo -e "   ${BLUE}$CONFIG_FILE${NC}"
echo "   Update the following parameters:"
if [ "$CLOUD_PROVIDER" == "proxmox" ]; then
    echo "   - proxmox_api_url (your Proxmox server URL)"
    echo "   - proxmox_api_token_secret (API token from Proxmox)"
    echo "   - proxmox_node (your Proxmox node name)"
    echo "   - gateway, dns_servers (your network settings)"
    echo "   - template_vm_id (after creating VM template)"
fi
echo ""
echo "2. ${YELLOW}Create VM template in Proxmox:${NC}"
echo "   See documentation: docs/setup_guide.md"
echo "   Quick summary:"
echo "   - Download Ubuntu 22.04 cloud-image or install from ISO"
echo "   - Install cloud-init, python3, qemu-guest-agent"
echo "   - Convert to template"
echo "   - Note the template ID"
echo ""
echo "3. ${YELLOW}Deploy infrastructure:${NC}"
echo -e "   ${BLUE}cd terraform${NC}"
echo -e "   ${BLUE}terraform plan -var-file=\"environments/$ENVIRONMENT/${CLOUD_PROVIDER}.tfvars\" -var-file=\"templates/${TEMPLATE}.tfvars\"${NC}"
echo -e "   ${BLUE}terraform apply -var-file=\"environments/$ENVIRONMENT/${CLOUD_PROVIDER}.tfvars\" -var-file=\"templates/${TEMPLATE}.tfvars\"${NC}"
echo ""
echo "4. ${YELLOW}Or use the automated installer:${NC}"
echo -e "   ${BLUE}cd $PROJECT_ROOT${NC}"
echo -e "   ${BLUE}./scripts/install.sh -e $ENVIRONMENT -t $TEMPLATE -c $CLOUD_PROVIDER${NC}"
echo ""
echo -e "${BLUE}For more information, see:${NC}"
echo "   - docs/setup_guide.md - Detailed setup guide"
echo "   - docs/quickstart.md - Quick start guide"
echo "   - README.md - Project overview"
echo ""
