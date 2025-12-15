output "postgres_password" {
  description = "Generated PostgreSQL password"
  value       = random_password.postgres_password.result
  sensitive   = true
}

output "postgres_secret_name" {
  description = "Kubernetes Secret name containing PostgreSQL credentials"
  value       = kubernetes_secret.postgres_credentials.metadata[0].name
}

output "postgres_host" {
  description = "Kubernetes Service name for PostgreSQL access"
  value       = "${kubernetes_service_v1.postgres_svc.metadata[0].name}.${var.authentik_namespace}.svc.cluster.local"
}