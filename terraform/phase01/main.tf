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

# Deploy Cilium (Gateway API is enabled)
module "cilium" {
  source               = "./modules/cilium"
  chart_namespace      = "kube-system"
  chart_version        = "1.18.5"
  gateway_api_version  = "v1.2.0"
  cluster_service_host = var.cluster_service_host
}

# Deploy cert-manager
module "cert_manager" {
  source               = "./modules/cert-manager"
  chart_namespace      = "cert-manager"
  chart_version        = "v1.19.0"
  cloudflare_api_token = var.cloudflare_api_token

  depends_on = [module.cilium]
}

# Deploy rook-ceph
module "rook_ceph" {
  source          = "./modules/rook-ceph"
  chart_namespace = "rook-ceph"
  chart_version   = "v1.18.9"

  depends_on = [module.cilium]
}
