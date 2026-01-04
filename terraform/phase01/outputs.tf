output "cluster_issuer_secret_name" {
  description = "Cloudflare API token Kubernetes secret name for DNS validation"
  value       = module.cert_manager.cluster_issuer_secret_name
}