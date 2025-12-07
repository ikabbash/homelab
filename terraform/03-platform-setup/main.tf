terraform {
  required_version = ">= 1.0"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
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

data "terraform_remote_state" "core_services" {
  backend = "local"
  config = {
    path = "../02-core-services/terraform.tfstate"
  }
}

locals {
  core_services = data.terraform_remote_state.core_services.outputs
}

# Setup Vault configs
module "vault_setup" {
  source     = "./modules/vault-configs"
  vault_port = var.vault_port
}

# Setup VSO configs
module "vso_setup" {
  source        = "./modules/vso-configs"
  vault_port    = var.vault_port
  vault_address = local.core_services.vault_address
  vso_namespace = local.core_services.vso_namespace

  vso_role_name        = module.vault_setup.vso_role_name
  kubernetes_auth_path = module.vault_setup.kubernetes_auth_path
  vso_audience         = module.vault_setup.vso_audience
  vso_bound_namespaces = module.vault_setup.vso_bound_namespaces
  vso_service_account  = module.vault_setup.vso_service_account

  depends_on = [module.vault_setup]
}

# Deploy ArgoCD
module "argocd" {
  source                 = "./modules/argocd"
  chart_namespace        = "argocd"
  chart_version          = "9.1.6"
  homelab_domain         = local.core_services.homelab_domain
  gateway_name           = local.core_services.gateway_name
  gateway_namespace      = local.core_services.gateway_namespace
  gateway_listener_https = local.core_services.gateway_listener_https
}
