# Optional
variable "chart_namespace" {
  description = "The Kubernetes namespace to deploy cert-manager into"
  type        = string
  default     = "cert-manager"
}

# Required
variable "chart_version" {
  description = "cert-manager Helm chart version"
  type        = string
}

# Required
variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS validation"
  type        = string
  sensitive   = true
}

# Optional
variable "cloudflare_secret_name" {
  description = "Cloudflare API token Kubernetes secret name for DNS validation"
  type        = string
  default     = "cloudflare-api-token-secret"
}

# Optional
variable "cluster_issuer_name" {
  description = "Cert Manager's Cluster Issuer name"
  type        = string
  default     = "letsencrypt-prod"
}

# Required
variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt notifications"
  type        = string
}