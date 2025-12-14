output "postgres_password" {
  description = "Generated PostgreSQL password"
  value       = random_password.postgres_password.result
  sensitive   = true
}

output "postgres_secret_name" {
  description = ""
  value       = kubernetes_secret.postgres_credentials.metadata[0].name
}