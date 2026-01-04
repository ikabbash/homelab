output "cluster_issuer_name" {
  description = "Cert Manager's Cluster Issuer name for Vault certificate creation"
  value       = var.cluster_issuer_name
}

output "gateway_name" {
  description = "Name of the Gateway resource"
  value       = var.gateway_name
}

output "gateway_namespace" {
  description = "Namespace of the Gateway resource"
  value       = var.gateway_namespace
}

output "gateway_external_ip" {
  description = "Load balancer external IP for Gateway API"
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

output "gateway_listener_vault" {
  description = "Listener name for Vault TLS passthrough"
  value       = var.gateway_listener_vault
}
