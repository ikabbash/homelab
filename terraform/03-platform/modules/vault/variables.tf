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
variable "vault_pv_name" {
  description = "Name of the persistent volume used by Vault"
  type        = string
  default     = "vault-pv"
}

# Optional
variable "vault_pvc_name" {
  description = "Name of the persistent volume claim bound to the Vault persistent volume"
  type        = string
  default     = "vault-pvc"
}

# Optional
variable "vault_storage_size" {
  description = "Storage size allocated for the Vault persistent volume"
  type        = string
  default     = "10Gi"
}

# Required
variable "homelab_domain" {
  description = "Domain name for the homelab environment"
  type        = string
}

# Optional
variable "vault_subdomain" {
  description = "Subdomain for the Vault service"
  type        = string
  default     = "vault"
}

# Required
variable "homelab_data_path" {
  description = "Base path for homelab data storage"
  type        = string
}

# Required
variable "cluster_issuer_name" {
  description = "The name of the ClusterIssuer from cert-manager module"
  type        = string
}

# Optional
variable "vault_secret_name" {
  description = "Name of the Kubernetes TLS secret used by Vault"
  type        = string
  default     = "vault-server-tls"
}