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

locals {
  phase02 = data.terraform_remote_state.phase02.outputs
}

# Deploy ArgoCD
module "argocd" {
  source                 = "./modules/argocd"
  chart_namespace        = "argocd"
  chart_version          = "9.1.6"
  homelab_domain         = local.phase02.homelab_domain
  gateway_name           = local.phase02.gateway_name
  gateway_namespace      = local.phase02.gateway_namespace
  gateway_listener_https = local.phase02.gateway_listener_https
}
