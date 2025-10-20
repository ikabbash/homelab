output "cluster_issuer_name" {
  description = "The name of the ClusterIssuer"
  value       = module.cert_manager.cluster_issuer_name
}

output "vault_address" {
  description = "Complete domain name where the Vault service will be accessible"
  value       = module.vault.address
}

output "vault_namespace" {
  description = "The namespace where Vault is deployed"
  value       = module.vault.namespace
}

output "vso_namespace" {
  description = "The namespace where VSO is deployed"
  value       = module.vso.namespace
}

output "homelab_domain" {
  description = "Domain name for the homelab environment"
  value       = var.homelab_domain
}