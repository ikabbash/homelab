output "vso_namespace" {
  description = "The namespace where VSO is deployed"
  value       = helm_release.vso.namespace
}
