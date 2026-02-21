output "vault_namespace" {
  description = "The namespace where Vault is deployed"
  value       = module.vault.vault_namespace
}

output "vault_host" {
  description = "Vault service hostname where Vault will be accessible"
  value       = module.vault.vault_host
}

output "vault_audit_file_path" {
  description = "Mount path where the Vault audit log file will be stored"
  value       = module.vault.vault_audit_file_path
}

output "vso_namespace" {
  description = "The namespace where VSO is deployed"
  value       = module.vso.vso_namespace
}

output "gateway_name" {
  description = "Name of the Gateway resource"
  value       = module.gateway.gateway_name
}

output "gateway_namespace" {
  description = "Namespace of the Gateway resource"
  value       = module.gateway.gateway_namespace
}

output "gateway_listener_https" {
  description = "Listener name for wildcard HTTPS traffic"
  value       = module.gateway.gateway_listener_https
}

output "gateway_listener_http" {
  description = "Listener name for HTTP traffic"
  value       = module.gateway.gateway_listener_https
}

output "homelab_domain" {
  description = "Domain name for the homelab environment"
  value       = var.homelab_domain
}