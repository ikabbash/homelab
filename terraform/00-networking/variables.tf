# Optional
variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

# Required
variable "cluster_service_host" {
  description = "Control plane API IP or VIP for Cilium"
  type        = string
}

# Required
variable "lb_external_ip" {
  description = "Load balancer external IP for either Ingress Controller or Gateway API"
  type        = string
}

# Optional
variable "gateway_name" {
  description = "Name of the main Gateway for all namespaces"
  type        = string
  default     = "homelab-gw"
}

# Optional
variable "gateway_enable" {
  description = "Decides cluster entrypoint, true for Gateway API, false for NGINX Ingress Controller"
  type        = bool
  default     = true
}

# Required
variable "homelab_domain" {
  description = "Domain name for the homelab environment"
  type        = string
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