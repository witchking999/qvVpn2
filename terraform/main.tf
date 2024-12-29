terraform {
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.13.5"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "tailscale" {
  api_key = var.tailscale_api_token
}

resource "null_resource" "create_directories" {
  provisioner "local-exec" {
    command = "bash ./scripts/create_directories.sh"
  }
}

module "vault" {
  source = "./modules/vault"
}

module "cassandra" {
  source = "./modules/cassandra"
}

module "tailscale" {
  source     = "./modules/tailscale"
  auth_key   = var.tailscale_auth_key
  api_token  = var.tailscale_api_token
}

output "vault_address" {
  description = "Vault server address"
  value       = "http://127.0.0.1:8200"
}

output "tailscale_status" {
  description = "Tailscale VPN status"
  value       = module.tailscale.status
}
