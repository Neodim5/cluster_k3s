# Proxmox provider configuration
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.3-rc02"
    }
  }
  
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "proxmox" {
  pm_api_url   = var.proxmox_api_url
  pm_api_token = var.proxmox_api_token
  
  # Skip TLS verification for self-signed certificates (development only)
  pm_tls_insecure = true
}
