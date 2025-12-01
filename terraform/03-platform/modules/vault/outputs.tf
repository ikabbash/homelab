output "namespace" {
  description = "The namespace where Vault is deployed"
  value       = helm_release.vault.namespace
}

output "address" {
  description = "Complete domain name where the Vault service will be accessible"
  value       = "${var.vault_subdomain}.${var.homelab_domain}"
}