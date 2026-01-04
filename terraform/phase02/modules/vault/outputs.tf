output "vault_namespace" {
  description = "The namespace where Vault is deployed"
  value       = var.chart_namespace
}

output "vault_address" {
  description = "Complete domain name where the Vault service will be accessible"
  value       = var.vault_address
}