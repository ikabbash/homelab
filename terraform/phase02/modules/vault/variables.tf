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

# Required
variable "cluster_issuer_name" {
  description = "The name of the ClusterIssuer from cert-manager module"
  type        = string
}

# Optional
variable "vault_certificate_name" {
  description = "Name of the Kubernetes TLS secret used by Vault"
  type        = string
  default     = "vault-server-tls"
}

# Required
variable "gateway_name" {
  description = "Name of the Gateway resource"
  type        = string
}

# Required
variable "gateway_namespace" {
  description = "Namespace of the Gateway resource"
  type        = string
}

# Required
variable "gateway_listener_http" {
  description = "Listener name for HTTP traffic"
  type        = string
}

# Required
variable "gateway_listener_vault" {
  description = "Listener name for Vault TLS passthrough"
  type        = string
}

# Required
variable "enable_monitoring" {
  description = "Enables monitoring integration. Requires Prometheus Operator to be deployed first"
  type        = bool
}