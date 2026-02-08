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

data "terraform_remote_state" "phase01" {
  backend = "local"
  config = {
    path = "../phase01/terraform.tfstate"
  }
}

locals {
  phase01    = data.terraform_remote_state.phase01.outputs
  vault_host = "${var.vault_subdomain}.${var.homelab_domain}"
}

# Setup Gateway
module "gateway" {
  source                     = "./modules/gateway"
  gateway_external_ip        = var.gateway_external_ip
  homelab_domain             = var.homelab_domain
  letsencrypt_email          = var.letsencrypt_email
  cluster_issuer_secret_name = local.phase01.cluster_issuer_secret_name
  vault_host                 = local.vault_host
}

# Deploy Vault
module "vault" {
  source                 = "./modules/vault"
  chart_namespace        = "vault"
  chart_version          = "0.31.0"
  vault_host             = local.vault_host
  cluster_issuer_name    = module.gateway.cluster_issuer_name
  gateway_name           = module.gateway.gateway_name
  gateway_namespace      = module.gateway.gateway_namespace
  gateway_listener_http  = module.gateway.gateway_listener_http
  gateway_listener_vault = module.gateway.gateway_listener_vault
  storage_class_name     = local.phase01.host_storage_class_name
}

# Deploy VSO
module "vso" {
  source          = "./modules/vso"
  chart_namespace = "vault-secrets-operator-system"
  chart_version   = "1.0.1"
  vault_host      = local.vault_host

  depends_on = [module.vault]
}
