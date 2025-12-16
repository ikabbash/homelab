# Required
variable "authentik_namespace" {
  description = "The namespace where Authentik will be deployed into"
  type        = string
}

# Required
variable "homelab_data_path" {
  description = "Base path for homelab data storage"
  type        = string
}

# Optional
variable "redis_storage_size" {
  description = "Storage size for Redis"
  type        = string
  default     = "5Gi"
}

# Optional
variable "redis_pvc_name" {
  description = "Persistent Volume Claim name for Redis"
  type        = string
  default     = "authentik-redis-pvc"
}