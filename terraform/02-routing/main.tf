terraform {
  required_version = ">= 1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Setup Cluster Issuer
module "cluster_issuer" {
  source                 = "./modules/cluster-issuer"
  cloudflare_api_token   = var.cloudflare_api_token
  letsencrypt_email      = var.letsencrypt_email
  cert_manager_namespace = data.terraform_remote_state.networking.outputs.cert_manager_namespace
}

# Setup Gateway
module "gateway" {
  source              = "./modules/gateway"
  cluster_issuer_name = module.cluster_issuer.cluster_issuer_name
  lb_external_ip      = var.lb_external_ip
  homelab_domain      = var.homelab_domain

  depends_on = [module.cluster_issuer]
}

# Setup Cilium LB-IPAM and L2 Announcement Policy for accessibility
module "lb_config" {
  source            = "./modules/lb-config"
  gateway_name      = module.gateway.gateway_name
  gateway_namespace = module.gateway.gateway_namespace
  lb_external_ip    = var.lb_external_ip

  depends_on = [module.gateway]
}
