# Optional
variable "chart_namespace" {
  description = "The Kubernetes namespace to deploy Vault into"
  type        = string
  default     = "vault"
}

# Required
variable "chart_version" {
  description = "Vault Helm chart version"
  type        = string
}

# Optional
variable "vault_storage_size" {
  description = "Storage size allocated for the Vault persistent volume"
  type        = string
  default     = "10Gi"
}

# Optional
variable "vault_audit_storage_size" {
  description = "Storage size allocated for the Vault audit device persistent volume"
  type        = string
  default     = "10Gi"
}

# Optional
variable "vault_audit_file_path" {
  description = "Mount path where the Vault audit log file will be stored"
  type        = string
  default     = "/var/log/vault"
}

# Required
variable "vault_host" {
  description = "Vault service hostname where Vault will be accessible"
  type        = string
}

# Required
variable "storage_class_name" {
  description = "Name of the Kubernetes StorageClass used to provision Vault persistent storage"
  type        = string
}

# Optional
variable "vault_ca_secret_name" {
  description = ""
  type        = string
  default     = "vault-ca-secret"
}

# Optional
variable "vault_tls_secret_name" {
  description = ""
  type        = string
  default     = "vault-tls-secret"
}

# Required
variable "enable_monitoring" {
  description = "Enables monitoring integration. Requires Prometheus Operator to be deployed first"
  type        = bool
}