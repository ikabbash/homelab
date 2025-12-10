output "argocd_namespace" {
  description = "The namespace where ArgoCD is deployed"
  value       = helm_release.argocd.namespace
}

output "argocd_address" {
  description = "The domain where ArgoCD is accessible"
  value       = "${var.argocd_subdomain}.${var.homelab_domain}"
}
