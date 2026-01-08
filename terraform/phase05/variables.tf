# Optional
variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

# Required
variable "authentik_api_token" {
  description = "Authentik admin API token for Terraform"
  type        = string
}

# Optional
variable "argocd_subdomain" {
  description = "Subdomain for the Argo CD service"
  type        = string
  default     = "argocd"
}