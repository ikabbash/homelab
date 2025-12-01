# output "cluster_issuer_name" {
#   description = "The name of the ClusterIssuer"
#   value       = module.cert_manager.cluster_issuer_name
# }

output "homelab_domain" {
  description = "Domain name for the homelab environment"
  value       = var.homelab_domain
}

output "homelab_mount" {
  description = "Base path for homelab volume"
  value       = var.homelab_mount
}