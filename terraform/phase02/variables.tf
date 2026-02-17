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

# Required
variable "gateway_external_ip" {
  description = "Load balancer external IP for Gateway API"
  type        = string
}

# Required
variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt notifications"
  type        = string
}

# Optional
variable "vault_subdomain" {
  description = "Subdomain for the Vault service"
  type        = string
  default     = "vault"
}

# Required
variable "enable_monitoring" {
  description = "Enables monitoring integration. Requires Prometheus Operator to be deployed first"
  type        = bool
}