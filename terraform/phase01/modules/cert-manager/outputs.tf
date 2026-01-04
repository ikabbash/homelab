output "cluster_issuer_secret_name" {
  description = "Cloudflare API token Kubernetes secret name for DNS validation"
  value       = kubernetes_secret_v1.cluster_issuer_secret_name.metadata[0].name
}