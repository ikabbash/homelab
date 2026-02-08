# Required
variable "homelab_domain" {
  description = "Domain name for the homelab environment"
  type        = string
}

# Required
variable "argocd_host" {
  description = "Argo CD service hostname where Argo CD will be accessible"
  type        = string
}

# Required
variable "authentik_host" {
  description = "Authentik service hostname where Authentik will be accessible"
  type        = string
}

# Required
variable "authentik_api_token" {
  description = "Authentik admin API token for Terraform"
  type        = string
}