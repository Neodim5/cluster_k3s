# Proxmox provider configuration
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9.0"
    }
  }
}

provider "proxmox" {
  pm_api_url   = var.proxmox_api_url
  pm_api_token = var.proxmox_api_token
  
  # Skip TLS verification for self-signed certificates (development only)
  pm_tls_insecure = true
}

# Local backend for state storage
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
