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
  gateway_enable       = var.gateway_enable
  cluster_service_host = var.cluster_service_host
  lb_external_ip       = var.lb_external_ip
  gateway_name         = var.gateway_name
}

# Deploy Gateway resource (if Cilium Gateway API is enabled)
module "gateway" {
  source         = "./modules/gateway"
  count          = var.gateway_enable ? 1 : 0 # If true, module is created
  lb_external_ip = var.lb_external_ip
  gateway_name   = var.gateway_name

  depends_on = [module.cilium]
}

# Deploy NGINX Ingress Controller
module "ingress_controller" {
  source          = "./modules/ingress-controller"
  count           = var.gateway_enable ? 0 : 1 # If false, module is created
  lb_external_ip  = var.lb_external_ip
  chart_namespace = "nginx-ingress"
  chart_version   = "2.3.1"

  depends_on = [module.cilium]
}

# Deploy cert-manager
module "cert_manager" {
  source               = "./modules/cert-manager"
  chart_namespace      = "cert-manager"
  chart_version        = "v1.19.0"
  cloudflare_api_token = var.cloudflare_api_token
  letsencrypt_email    = var.letsencrypt_email

  depends_on = [module.gateway, module.ingress_controller]
}