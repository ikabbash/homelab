output "infra_kv_mount_path" {
  description = "Path of the KV-v2 secret mount for homelab infrastructure"
  value       = vault_mount.homelab_infra_kv.path
}

output "apps_kv_mount_path" {
  description = "Path of the KV-v2 secret mount for homelab applications"
  value       = vault_mount.homelab_apps_kv.path
}

output "vso_role_name" {
  description = "Name of the Kubernetes auth backend role for VSO"
  value       = vault_kubernetes_auth_backend_role.vso_role.role_name
}

output "kubernetes_auth_path" {
  description = "Path where the VSO Kubernetes auth backend is enabled"
  value       = vault_auth_backend.vso_kubernetes.path
}

output "vso_audience" {
  description = "Audience configured for the VSO Kubernetes auth role"
  value       = vault_kubernetes_auth_backend_role.vso_role.audience
}

output "vso_bound_namespaces" {
  description = "Namespaces bound to the VSO Kubernetes auth role"
  value       = tolist(vault_kubernetes_auth_backend_role.vso_role.bound_service_account_namespaces)
}

output "vso_service_account" {
  description = "VSO service account name for every namespace"
  value       = tolist(vault_kubernetes_auth_backend_role.vso_role.bound_service_account_names)[0]
}