terraform {
  required_version = ">= 1.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }
}

# Deploy Cilium (Gateway API is enabled)
module "cilium" {
  source               = "./modules/cilium"
  chart_namespace      = "kube-system"
  # renovate: datasource=helm depName=cilium registryUrl=https://helm.cilium.io/
  chart_version        = "1.20.0"
  gateway_api_version  = "v1.6.1"
  cluster_service_host = var.cluster_service_host
  enable_monitoring    = var.enable_monitoring
}

# Deploy cert-manager
module "cert_manager" {
  source               = "./modules/cert-manager"
  chart_namespace      = "cert-manager"
  # renovate: datasource=helm depName=cert-manager registryUrl=https://charts.jetstack.io
  chart_version        = "v1.21.1"
  cloudflare_api_token = var.cloudflare_api_token

  depends_on = [module.cilium]
}

# Deploy OpenEBS
module "openebs" {
  source          = "./modules/openebs"
  chart_namespace = "openebs"
  # renovate: datasource=helm depName=openebs registryUrl=https://openebs.github.io/openebs
  chart_version   = "4.5.1"

  depends_on = [module.cilium]
}