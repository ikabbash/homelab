output "cert_manager_namespace" {
  description = "The namespace where Cert Manager is deployed"
  value       = module.cert_manager.chart_namespace
}