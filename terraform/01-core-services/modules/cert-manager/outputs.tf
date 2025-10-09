output "release_name" {
  description = "The name of the cert-manager Helm release"
  value       = helm_release.cert_manager.name
}

output "namespace" {
  description = "The namespace where cert-manager is deployed"
  value       = helm_release.cert_manager.namespace
}

output "cluster_issuer_name" {
  description = "The name of the ClusterIssuer"
  value       = var.cluster_issuer_name
}