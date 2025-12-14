# Required
variable "authentik_namespace" {
  description = "The namespace where Authentik will be deployedinto"
  type        = string
}

# Optional
variable "postgres_user" {
  description = "PostgreSQL user"
  type        = string
  default     = "postgres"
}

# Required
variable "homelab_data_path" {
  description = "Base path for homelab data storage"
  type        = string
}

# Optional
variable "postgres_storage_size" {
  description = "Storage size for PostgreSQL"
  type        = string
  default     = "5Gi"
}