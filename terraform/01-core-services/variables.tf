variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
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