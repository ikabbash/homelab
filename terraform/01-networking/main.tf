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
  chart_version        = "1.18.4"
  gateway_api_version  = "v1.2.0"
  cluster_service_host = var.cluster_service_host
  lb_external_ip       = var.lb_external_ip
  gateway_name         = var.gateway_name
}

# Deploy cert-manager
module "cert_manager" {
  source               = "./modules/cert-manager"
  chart_namespace      = "cert-manager"
  chart_version        = "v1.19.0"
  cloudflare_api_token = var.cloudflare_api_token
  letsencrypt_email    = var.letsencrypt_email

  depends_on = [module.cilium]
}

# Deploy Gateway resource (if Cilium Gateway API is enabled)
module "gateway" {
  source              = "./modules/gateway"
  lb_external_ip      = var.lb_external_ip
  gateway_name        = var.gateway_name
  homelab_domain      = var.homelab_domain
  cluster_issuer_name = module.cert_manager.cluster_issuer_name

  depends_on = [module.cert_manager]
}

# module "volumes_init" {
#   source        = "./modules/volumes-init"
#   homelab_mount = var.homelab_mount

#   depends_on = [module.gateway]
# }
