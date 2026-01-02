output "argocd_client_id" {
  description = "OAuth2 Client ID for ArgoCD"
  value       = authentik_provider_oauth2.argocd.client_id
}

output "argocd_client_secret" {
  description = "OAuth2 Client Secret for ArgoCD"
  value       = authentik_provider_oauth2.argocd.client_secret
  sensitive   = true
}

output "argocd_issuer_url" {
  description = "OIDC Issuer URL for ArgoCD DEX configuration"
  value       = "https://${var.authentik_address}/application/o/${authentik_application.argocd.slug}/"
}