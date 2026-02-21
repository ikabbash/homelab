output "vault_namespace" {
  description = "The namespace where Vault is deployed"
  value       = var.chart_namespace
}

output "vault_host" {
  description = "Vault service hostname where Vault will be accessible"
  value       = var.vault_host
}

output "vault_audit_file_path" {
  description = "Mount path where the Vault audit log file will be stored"
  value       = var.vault_audit_file_path
}