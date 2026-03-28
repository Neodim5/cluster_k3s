#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     K3S Cluster Installer - Dependencies Checker         ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get version
get_version() {
    local cmd=$1
    local version_flag=${2:---version}
    $cmd $version_flag 2>&1 | head -n 1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1
}

echo -e "${YELLOW}Checking required dependencies...${NC}"
echo ""

# Check Terraform
TERRAFORM_MIN_VERSION="1.5.0"
if command_exists terraform; then
    TERRAFORM_VERSION=$(get_version terraform)
    print_status "ok" "Terraform is installed (v$TERRAFORM_VERSION)"
else
    print_status "error" "Terraform is not installed"
    TERRAFORM_INSTALLED=false
fi

# Check Ansible
ANSIBLE_MIN_VERSION="2.10.0"
if command_exists ansible; then
    ANSIBLE_VERSION=$(get_version ansible --version)
    print_status "ok" "Ansible is installed (v$ANSIBLE_VERSION)"
else
    print_status "error" "Ansible is not installed"
    ANSIBLE_INSTALLED=false
fi

# Check kubectl
if command_exists kubectl; then
    KUBECTL_VERSION=$(get_version kubectl --client)
    print_status "ok" "kubectl is installed (v$KUBECTL_VERSION)"
else
    print_status "warning" "kubectl is not installed (will be needed for cluster management)"
fi

# Check k3sup (optional)
if command_exists k3sup; then
    K3SUP_VERSION=$(get_version k3sup)
    print_status "ok" "k3sup is installed (v$K3SUP_VERSION) ${BLUE}(optional)${NC}"
else
    print_status "info" "k3sup is not installed (optional, needed only if using k3sup method)"
fi

# Check SSH
if command_exists ssh; then
    print_status "ok" "SSH client is available"
else
    print_status "error" "SSH client is not installed"
fi

# Check SSH key
if [ -f ~/.ssh/id_rsa.pub ] || [ -f ~/.ssh/id_ed25519.pub ]; then
    print_status "ok" "SSH key found"
else
    print_status "warning" "No SSH key found (~/.ssh/id_rsa.pub or ~/.ssh/id_ed25519.pub)"
    print_status "info" "Generate one with: ssh-keygen -t ed25519 -N ''"
fi

echo ""
echo -e "${YELLOW}Checking optional dependencies...${NC}"
echo ""

# Check Git
if command_exists git; then
    GIT_VERSION=$(get_version git)
    print_status "ok" "Git is installed (v$GIT_VERSION)"
else
    print_status "warning" "Git is not installed"
fi

# Check Python3
if command_exists python3; then
    PYTHON3_VERSION=$(get_version python3)
    print_status "ok" "Python 3 is installed (v$PYTHON3_VERSION)"
else
    print_status "warning" "Python 3 is not installed (needed for some scripts)"
fi

# Check curl
if command_exists curl; then
    print_status "ok" "curl is available"
else
    print_status "warning" "curl is not installed"
fi

# Check wget
if command_exists wget; then
    print_status "ok" "wget is available"
else
    print_status "warning" "wget is not installed"
fi

echo ""
echo -e "${YELLOW}Checking project structure...${NC}"
echo ""

# Check terraform directory
if [ -d "$PROJECT_ROOT/terraform" ]; then
    print_status "ok" "Terraform directory exists"
else
    print_status "error" "Terraform directory not found"
fi

# Check ansible directory
if [ -d "$PROJECT_ROOT/ansible" ]; then
    print_status "ok" "Ansible directory exists"
else
    print_status "error" "Ansible directory not found"
fi

# Check templates
if [ -f "$PROJECT_ROOT/terraform/templates/simple.tfvars" ]; then
    print_status "ok" "Template 'simple' found"
else
    print_status "error" "Template 'simple' not found"
fi

if [ -f "$PROJECT_ROOT/terraform/templates/middle.tfvars" ]; then
    print_status "ok" "Template 'middle' found"
else
    print_status "error" "Template 'middle' not found"
fi

if [ -f "$PROJECT_ROOT/terraform/templates/custom.tfvars" ]; then
    print_status "ok" "Template 'custom' found"
else
    print_status "error" "Template 'custom' not found"
fi

# Check environment configs
if [ -f "$PROJECT_ROOT/terraform/environments/dev/proxmox.tfvars.example" ]; then
    print_status "ok" "Proxmox example config found"
else
    print_status "warning" "Proxmox example config not found"
fi

if [ -f "$PROJECT_ROOT/terraform/proxmox.tfvars" ]; then
    print_status "ok" "Proxmox config file exists"
else
    print_status "warning" "Proxmox config file not found (copy from example)"
fi

echo ""
echo -e "${YELLOW}Summary:${NC}"
echo ""

MISSING_CRITICAL=0
MISSING_OPTIONAL=0

if [ "$TERRAFORM_INSTALLED" != "false" ] && [ "$ANSIBLE_INSTALLED" != "false" ]; then
    print_status "ok" "All critical dependencies are installed"
else
    MISSING_CRITICAL=1
    print_status "error" "Some critical dependencies are missing"
fi

if ! command_exists kubectl; then
    ((MISSING_OPTIONAL++))
fi

if ! command_exists k3sup; then
    ((MISSING_OPTIONAL++))
fi

if [ $MISSING_OPTIONAL -gt 0 ]; then
    print_status "info" "$MISSING_OPTIONAL optional dependency(-ies) not installed"
fi

echo ""

if [ $MISSING_CRITICAL -eq 0 ]; then
    echo -e "${GREEN}✓ All critical dependencies are satisfied!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Copy and configure proxmox.tfvars:"
    echo -e "   ${BLUE}cp terraform/environments/dev/proxmox.tfvars.example terraform/environments/dev/proxmox.tfvars${NC}"
    echo "   Edit the file with your Proxmox settings"
    echo ""
    echo "2. Create VM template in Proxmox (see docs/setup_guide.md)"
    echo ""
    echo "3. Initialize Terraform:"
    echo -e "   ${BLUE}cd terraform && terraform init${NC}"
    echo ""
    echo "4. Deploy cluster:"
    echo -e "   ${BLUE}./scripts/install.sh -e dev -t simple -c proxmox${NC}"
    exit 0
else
    echo -e "${RED}✗ Some critical dependencies are missing!${NC}"
    echo ""
    echo -e "${YELLOW}To install missing dependencies on Ubuntu/Debian:${NC}"
    echo ""
    echo "# Install Terraform:"
    echo "wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg"
    echo "echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com \$(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list"
    echo "sudo apt update && sudo apt install terraform"
    echo ""
    echo "# Install Ansible:"
    echo "sudo apt update && sudo apt install -y ansible"
    echo ""
    echo "# Install kubectl:"
    echo "curl -LO \"https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\""
    echo "chmod +x kubectl && sudo mv kubectl /usr/local/bin/"
    echo ""
    echo "# Install k3sup (optional):"
    echo "curl -sLS https://get.k3sup.dev | sh"
    echo "sudo mv k3sup /usr/local/bin/"
    echo ""
    echo "# Generate SSH key:"
    echo "ssh-keygen -t ed25519 -N ''"
    exit 1
fi
