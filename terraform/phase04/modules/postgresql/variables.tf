# Required
variable "authentik_namespace" {
  description = "The namespace where Authentik will be deployedinto"
  type        = string
}

# Optional
variable "postgres_user" {
  description = "PostgreSQL user"
  type        = string
  default     = "authentik"
}

# Optional
variable "postgres_db" {
  description = "Intial DB created"
  type        = string
  default     = "authentik"
}

# Optional
variable "postgres_storage_size" {
  description = "Storage size for PostgreSQL"
  type        = string
  default     = "5Gi"
}

# Required
variable "storage_class_name" {
  description = "Name of the Kubernetes StorageClass used to provision PostgreSQL persistent storage"
  type        = string
}