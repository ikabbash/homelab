terraform {
  required_version = ">= 1.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
}

# Deploy Cilium (Gateway API is enabled)
module "cilium" {
  source               = "./modules/cilium"
  chart_namespace      = "kube-system"
  chart_version        = "1.18.4"
  gateway_api_version  = "v1.2.0"
  cluster_service_host = var.cluster_service_host
}

# Deploy cert-manager
module "cert_manager" {
  source          = "./modules/cert-manager"
  chart_namespace = "cert-manager"
  chart_version   = "v1.19.0"

  depends_on = [module.cilium]
}
