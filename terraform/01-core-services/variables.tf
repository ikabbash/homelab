# Optional
variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

# Required
variable "homelab_domain" {
  description = "Domain name for the homelab environment"
  type        = string
}

# Optional
variable "homelab_data_path" {
  description = "Base path for homelab data storage"
  type        = string
  default     = "/var/mnt/homelab"
}

# Required
variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS validation"
  type        = string
  sensitive   = true
}

# Required
variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt notifications"
  type        = string
}