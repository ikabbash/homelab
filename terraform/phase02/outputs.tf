output "vault_namespace" {
  description = "The namespace where Vault is deployed"
  value       = module.vault.vault_namespace
}

output "vault_address" {
  description = "Complete domain name where the Vault service will be accessible"
  value       = module.vault.vault_address
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

output "homelab_data_path" {
  description = "Base path for homelab data storage"
  value       = var.homelab_data_path
}
