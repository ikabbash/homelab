output "postgres_password" {
  description = "Generated PostgreSQL password"
  value       = random_password.postgres_password.result
  sensitive   = true
}