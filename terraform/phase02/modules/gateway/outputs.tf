output "cluster_issuer_name" {
  description = "Cert Manager's Cluster Issuer name for Vault certificate creation"
  value       = var.cluster_issuer_name
}

output "gateway_name" {
  description = "Name of the wildcard Gateway resource (HTTP/HTTPS)"
  value       = var.gateway_name
}

output "gateway_namespace" {
  description = "Namespace of the Gateway resources"
  value       = var.gateway_namespace
}

output "gateway_external_ip" {
  description = "Load balancer external IP for the wildcard Gateway"
  value       = var.gateway_external_ip
}

output "gateway_listener_http" {
  description = "Listener name for HTTP traffic"
  value       = var.gateway_listener_http
}

output "gateway_listener_https" {
  description = "Listener name for wildcard HTTPS traffic"
  value       = var.gateway_listener_https
}

output "vault_gateway_name" {
  description = "Name of the Vault TLS passthrough Gateway resource"
  value       = var.vault_gateway_name
}

output "vault_gateway_external_ip" {
  description = "Load balancer external IP for the Vault Gateway"
  value       = var.vault_gateway_external_ip
}

output "gateway_listener_vault" {
  description = "Listener name for Vault TLS passthrough"
  value       = var.gateway_listener_vault
}