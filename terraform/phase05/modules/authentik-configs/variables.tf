# Required
variable "argocd_address" {
  description = "Complete domain name for ArgoCD"
  type        = string
}

# Required
variable "authentik_address" {
  description = "Complete domain name for Authentik"
  type        = string
}

# Required
variable "authentik_api_token" {
  description = "Authentik admin API token for Terraform"
  type        = string
}