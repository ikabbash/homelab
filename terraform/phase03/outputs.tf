output "vso_role_name" {
  description = "Name of the Kubernetes auth backend role for VSO"
  value       = module.vault_setup.vso_role_name
}

output "vso_service_account" {
  description = "VSO service account name for every namespace"
  value       = module.vault_setup.vso_service_account
}

output "vso_namespace" {
  description = "The namespace where VSO is deployed"
  value       = data.terraform_remote_state.phase02.outputs.vso_namespace
}