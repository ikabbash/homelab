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

data "terraform_remote_state" "phase02" {
  backend = "local"
  config = {
    path = "../phase02/terraform.tfstate"
  }
}

data "terraform_remote_state" "phase04" {
  backend = "local"
  config = {
    path = "../phase04/terraform.tfstate"
  }
}

locals {
  phase02 = data.terraform_remote_state.phase02.outputs
  phase04 = data.terraform_remote_state.phase04.outputs
}

# Setup Authentik
module "authentik_setup" {
  source              = "./modules/authentik-configs"
  authentik_address   = local.phase04.authentik_address
  authentik_api_token = var.authentik_api_token
  argocd_address      = "argocd.${local.phase02.homelab_domain}"
}

# Deploy ArgoCD
module "argocd" {
  source                 = "./modules/argocd"
  chart_namespace        = "argocd"
  chart_version          = "9.2.3"
  argocd_address         = "argocd.${local.phase02.homelab_domain}"
  gateway_name           = local.phase02.gateway_name
  gateway_namespace      = local.phase02.gateway_namespace
  gateway_listener_https = local.phase02.gateway_listener_https
}
