output "cluster_issuer_name" {
  description = "The name of the ClusterIssuer"
  value       = module.cluster_issuer.cluster_issuer_name
}

output "gateway_name" {
  description = "Name of the Gateway resource"
  value       = module.gateway.gateway_name
}

output "gateway_namespace" {
  description = "Namespace of the Gateway resource"
  value       = module.gateway.gateway_namespace
}

output "homelab_domain" {
  description = "Domain name for the homelab environment"
  value       = var.homelab_domain
}

output "lb_external_ip" {
  description = "Load balancer external IP for either Ingress Controller or Gateway API"
  value       = var.lb_external_ip
}
