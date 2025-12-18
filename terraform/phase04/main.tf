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

resource "kubernetes_namespace_v1" "authentik_namespace" {
  metadata {
    name = var.authentik_namespace
  }
}

module "postgresql" {
  source              = "./modules/postgresql"
  authentik_namespace = var.authentik_namespace
  homelab_data_path   = local.phase02.homelab_data_path

  depends_on = [kubernetes_namespace_v1.authentik_namespace]
}

module "redis" {
  source              = "./modules/redis"
  authentik_namespace = var.authentik_namespace
  homelab_data_path   = local.phase02.homelab_data_path

  depends_on = [kubernetes_namespace_v1.authentik_namespace]
}

module "authentik" {
  source                 = "./modules/authentik"
  chart_namespace        = var.authentik_namespace
  chart_version          = "2025.10.2"
  postgres_secret_name   = module.postgresql.postgres_secret_name
  postgres_host          = module.postgresql.postgres_host
  redis_host             = module.redis.redis_host
  homelab_data_path      = local.phase02.homelab_data_path
  homelab_domain         = local.phase02.homelab_domain
  gateway_name           = local.phase02.gateway_name
  gateway_namespace      = local.phase02.gateway_namespace
  gateway_listener_https = local.phase02.gateway_listener_https
  vso_auth_name          = var.vso_auth_name

  depends_on = [module.postgresql, module.redis]
}