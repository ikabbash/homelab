# Required
variable "chart_namespace" {
  description = "The Kubernetes namespace to deploy Authentik into"
  type        = string
}

# Required
variable "chart_version" {
  description = "Authentik Helm chart version"
  type        = string
}

# Required
variable "homelab_data_path" {
  description = "Base path for homelab data storage"
  type        = string
}

# Optional
variable "authentik_media_storage_size" {
  description = "Storage size for Authentik media PVC"
  type        = string
  default     = "5Gi"
}

# Optional
variable "authentik_media_pvc_name" {
  description = "Persistent Volume Claim name for Authentik media files"
  type        = string
  default     = "authentik-media-pvc"
}

# Optional
variable "authentik_templates_pvc_name" {
  description = "Persistent Volume Claim name for Authentik custom templates"
  type        = string
  default     = "authentik-templates-pvc"
}

# Optional
variable "authentik_templates_storage_size" {
  description = "Storage size for Authentik templates PVC"
  type        = string
  default     = "5Gi"
}

# Required
variable "postgres_secret_name" {
  description = "Name of the Kubernetes secret holding PostgreSQL credentials"
  type        = string
}

# Required
variable "postgres_host" {
  description = "PostgreSQL server address "
  type        = string
}

# Required
variable "redis_host" {
  description = "Redis server address"
  type        = string
}

# Required
variable "homelab_domain" {
  description = "Domain name for the homelab environment"
  type        = string
}

# Optional
variable "authentik_subdomain" {
  description = "Subdomain for the Authentik service"
  type        = string
  default     = "authentik"
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
variable "gateway_listener_https" {
  description = "Listener name for wildcard HTTPS traffic"
  type        = string
}

# Optional
variable "authentik_smtp_secret_name" {
  description = ""
  type        = string
  default     = "authentik-smtp-secret"
}

# Required
variable "vso_auth_name" {
  description = "Vault Secrets Operator's Auth manifest name"
  type        = string
}