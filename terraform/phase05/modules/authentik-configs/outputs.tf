output "argocd_client_id" {
  description = "OAuth2 Client ID for Argo CD"
  value       = authentik_provider_oauth2.argocd.client_id
}

output "argocd_client_secret" {
  description = "OAuth2 Client Secret for Argo CD"
  value       = authentik_provider_oauth2.argocd.client_secret
  sensitive   = true
}

output "argocd_issuer_url" {
  description = "OIDC Issuer URL for Argo CD Dex configuration"
  value       = "https://${var.authentik_host}/application/o/${authentik_application.argocd.slug}/"
}