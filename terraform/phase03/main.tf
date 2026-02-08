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

data "terraform_remote_state" "phase02" {
  backend = "local"
  config = {
    path = "../phase02/terraform.tfstate"
  }
}

locals {
  phase02 = data.terraform_remote_state.phase02.outputs
}

# Setup Vault configs
module "vault_setup" {
  source = "./modules/vault-configs"
}

# Setup VSO configs
module "vso_setup" {
  source               = "./modules/vso-configs"
  vault_host           = local.phase02.vault_host
  vso_namespace        = local.phase02.vso_namespace
  vso_role_name        = module.vault_setup.vso_role_name
  kubernetes_auth_path = module.vault_setup.kubernetes_auth_path
  vso_audience         = module.vault_setup.vso_audience
  vso_bound_namespaces = module.vault_setup.vso_bound_namespaces
  vso_service_account  = module.vault_setup.vso_service_account

  depends_on = [module.vault_setup]
}