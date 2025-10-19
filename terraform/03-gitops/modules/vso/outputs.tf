output "release_name" {
  description = "The Helm release name for VSO"
  value       = helm_release.vso.name
}

output "namespace" {
  description = "The namespace where VSO is deployed"
  value       = helm_release.vso.namespace
}