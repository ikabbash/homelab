terraform {
  required_version = ">= 1.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

data "terraform_remote_state" "networking" {
  backend = "local"
  config = {
    path = "../01-networking/terraform.tfstate"
  }
}

locals {
  vault_address = "${var.vault_subdomain}.${var.homelab_domain}"
}

# Setup Gateway
module "gateway" {
  source                 = "./modules/gateway"
  gateway_external_ip    = var.gateway_external_ip
  homelab_domain         = var.homelab_domain
  cloudflare_api_token   = var.cloudflare_api_token
  letsencrypt_email      = var.letsencrypt_email
  cert_manager_namespace = data.terraform_remote_state.networking.outputs.cert_manager_namespace
  vault_address          = local.vault_address
}

# Deploy Vault
module "vault" {
  source                 = "./modules/vault"
  chart_namespace        = "vault"
  chart_version          = "0.31.0"
  vault_address          = local.vault_address
  homelab_data_path      = var.homelab_data_path
  cluster_issuer_name    = module.gateway.cluster_issuer_name
  gateway_name           = module.gateway.gateway_name
  gateway_namespace      = module.gateway.gateway_namespace
  gateway_listener_http  = module.gateway.gateway_listener_http
  gateway_listener_vault = module.gateway.gateway_listener_vault
}

# Deploy VSO
module "vso" {
  source              = "./modules/vso"
  chart_namespace     = "vault-secrets-operator-system"
  chart_version       = "1.0.1"
  vault_address       = local.vault_address
  gateway_external_ip = module.gateway.gateway_external_ip

  depends_on = [module.vault]
}
