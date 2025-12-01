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

data "terraform_remote_state" "core_services" {
  backend = "local"
  config = {
    path = "../01-core-services/terraform.tfstate"
  }
}

data "terraform_remote_state" "vault_setup" {
  backend = "local"
  config = {
    path = "../02-vault-setup/terraform.tfstate"
  }
}

# Deploy ArgoCD
module "argocd" {
  source              = "./modules/argocd"
  chart_namespace     = "argocd"
  chart_version       = "9.0.1"
  cluster_issuer_name = data.terraform_remote_state.core_services.outputs.cluster_issuer_name
  homelab_domain      = data.terraform_remote_state.core_services.outputs.homelab_domain

  vso_role_name       = data.terraform_remote_state.vault_setup.outputs.vso_role_name
  vso_service_account = data.terraform_remote_state.vault_setup.outputs.vso_service_account
  vso_namespace       = data.terraform_remote_state.vault_setup.outputs.vso_namespace

  infra_kv_mount_path = data.terraform_remote_state.vault_setup.outputs.infra_kv_mount_path
}