# Optional
variable "gateway_name" {
  description = "Name of the Gateway resource"
  type        = string
  default     = "homelab-gw"
}

# Optional
variable "gateway_namespace" {
  description = "Namespace of the Gateway resource"
  type        = string
  default     = "cilium-gateway"
}

# Required
variable "gateway_external_ip" {
  description = "Load balancer external IP for Gateway API"
  type        = string
}

# Optional
variable "gateway_listener_http" {
  description = "Listener name for HTTP traffic"
  type        = string
  default     = "homelab-http"
}

# Optional
variable "gateway_listener_https" {
  description = "Listener name for wildcard HTTPS traffic"
  type        = string
  default     = "homelab-https"
}

# Optional
variable "gateway_listener_vault" {
  description = "Listener name for Vault TLS passthrough"
  type        = string
  default     = "vault-tls"
}

# Required
variable "homelab_domain" {
  description = "Domain name for the homelab environment"
  type        = string
}

# Required
variable "cluster_issuer_secret_name" {
  description = "Cloudflare API token Kubernetes secret name for DNS validation"
  type        = string
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

# Required
variable "vault_host" {
  description = "Vault service hostname where Vault will be accessible"
  type        = string
}
