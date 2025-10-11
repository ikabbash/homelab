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

# Deploy cert-manager
module "cert_manager" {
  source               = "./modules/cert-manager"
  chart_namespace      = "cert-manager"
  chart_version        = "v1.19.0"
  cloudflare_api_token = var.cloudflare_api_token
  letsencrypt_email    = var.letsencrypt_email
}

# Deploy Vault
module "vault" {
  source              = "./modules/vault"
  chart_namespace     = "vault"
  chart_version       = "0.31.0"
  homelab_domain      = var.homelab_domain
  homelab_data_path   = var.homelab_data_path
  cluster_issuer_name = module.cert_manager.cluster_issuer_name

  depends_on = [module.cert_manager]
}