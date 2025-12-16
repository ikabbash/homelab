output "redis_host" {
  description = "Kubernetes Service name for Redis access"
  value       = "${kubernetes_service_v1.redis_svc.metadata[0].name}.${var.authentik_namespace}.svc.cluster.local"
}