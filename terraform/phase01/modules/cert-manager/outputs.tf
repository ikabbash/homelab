output "chart_namespace" {
  description = "The namespace where Cert Manager is deployed"
  value       = helm_release.cert_manager.namespace
}