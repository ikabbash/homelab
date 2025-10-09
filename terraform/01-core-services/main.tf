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
