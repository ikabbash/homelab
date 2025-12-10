output "infra_kv_mount_path" {
  description = "Path of the KV-v2 secret mount for homelab infrastructure"
  value       = module.vault_setup.infra_kv_mount_path
}

output "vso_role_name" {
  description = "Name of the Kubernetes auth backend role for VSO"
  value       = module.vault_setup.vso_role_name
}

output "kubernetes_auth_path" {
  description = "Path where the VSO Kubernetes auth backend is enabled"
  value       = module.vault_setup.kubernetes_auth_path
}

output "vso_service_account" {
  description = "VSO service account name for every namespace"
  value       = module.vault_setup.vso_service_account
}

output "vso_namespace" {
  description = "The namespace where VSO is deployed"
  value       = data.terraform_remote_state.phase02.outputs.vso_namespace
}