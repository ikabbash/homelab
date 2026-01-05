# Optional
variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

# Optional
variable "authentik_namespace" {
  description = "The namespace where Authentik will be deployed into"
  type        = string
  default     = "authentik"
}

# Optional
variable "vso_auth_name" {
  description = "Vault Secrets Operator's Auth manifest name"
  type        = string
  default     = "default"
}