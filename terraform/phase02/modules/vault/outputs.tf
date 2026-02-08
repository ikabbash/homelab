output "vault_namespace" {
  description = "The namespace where Vault is deployed"
  value       = var.chart_namespace
}

output "vault_host" {
  description = "Vault service hostname where Vault will be accessible"
  value       = var.vault_host
}