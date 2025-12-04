terraform {
  required_version = ">= 1.0"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
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
    path = "../01-core-services/terraform.tfstate"
  }
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
  vault_address = data.terraform_remote_state.core_services.outputs.vault_address
  vso_namespace = data.terraform_remote_state.core_services.outputs.vso_namespace

  vso_role_name        = module.vault_setup.vso_role_name
  kubernetes_auth_path = module.vault_setup.kubernetes_auth_path
  vso_audience         = module.vault_setup.vso_audience
  vso_bound_namespaces = module.vault_setup.vso_bound_namespaces
  vso_service_account  = module.vault_setup.vso_service_account

  depends_on = [module.vault_setup]
}