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

resource "kubernetes_namespace_v1" "authentik_namespace" {
  metadata {
    name = var.authentik_namespace
  }
}

module "postgresql" {
  source              = "./modules/postgresql"
  authentik_namespace = var.authentik_namespace
  homelab_data_path   = data.terraform_remote_state.phase02.outputs.homelab_data_path

  depends_on = [kubernetes_namespace_v1.authentik_namespace]
}

module "redis" {
  source              = "./modules/redis"
  authentik_namespace = var.authentik_namespace
  homelab_data_path   = data.terraform_remote_state.phase02.outputs.homelab_data_path

  depends_on = [kubernetes_namespace_v1.authentik_namespace]
}