# Optional
variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

# Optional
variable "authentik_subdomain" {
  description = "Subdomain for the Authentik service"
  type        = string
  default     = "authentik"
}

# Optional
variable "authentik_namespace" {
  description = "The namespace where Authentik will be deployedinto"
  type        = string
  default     = "authentik"
}