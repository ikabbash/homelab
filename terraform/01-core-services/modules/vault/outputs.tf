output "release_name" {
  description = "The name of Vault Helm release"
  value       = helm_release.vault.name
}

output "namespace" {
  description = "The namespace where Vault is deployed"
  value       = helm_release.vault.namespace
}

output "domain" {
  description = "Complete domain name where the Vault service will be accessible"
  value       = "vault.${var.homelab_domain}"
}