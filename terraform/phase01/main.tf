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

# Deploy OpenEBS
module "openebs" {
  source          = "./modules/openebs"
  chart_namespace = "openebs"
  chart_version   = "4.4.0"

  depends_on = [module.cilium]
}