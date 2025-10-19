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

# Deploy VSO
module "vso" {
  source          = "./modules/vso"
  chart_namespace = "vault-secrets-operator-system"
  chart_version   = "1.0.1"
}

# Deploy ArgoCD
# module "argocd" {
#   source              = "./modules/argocd"
#   chart_namespace     = "argocd"
#   chart_version       = "8.6.1"
#   cluster_issuer_name = data.terraform_remote_state.core_services.outputs.cluster_issuer_name
#   homelab_domain      = data.terraform_remote_state.core_services.outputs.homelab_domain

#   depends_on = [module.vso]
# }