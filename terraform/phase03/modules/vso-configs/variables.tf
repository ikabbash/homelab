# Required
variable "vault_address" {
  description = "Complete domain name where the Vault service will be accessible"
  type        = string
}

# Required
variable "vso_namespace" {
  description = "The namespace where VSO is deployed"
  type        = string
}

# Optional
variable "vso_connection_name" {
  description = "Name of the Vault VSO connection"
  type        = string
  default     = "vault-default-connection"
}

# Required (AuthGlobal)
variable "vso_role_name" {
  description = "Name of the Kubernetes auth backend role for VSO"
  type        = string
}

# Required (AuthGlobal)
variable "kubernetes_auth_path" {
  description = "Path where the VSO Kubernetes auth backend is enabled"
  type        = string
}

# Required (AuthGlobal)
variable "vso_audience" {
  description = "Audience configured for the VSO Kubernetes auth role"
  type        = string
}

# Required (AuthGlobal)
variable "vso_bound_namespaces" {
  description = "Namespaces bound to the VSO Kubernetes auth role"
  type        = list(string)
}

# Required (AuthGlobal)
variable "vso_service_account" {
  description = "VSO service account name for every namespace"
  type        = string
}
