# Required
variable "chart_namespace" {
  description = "The Kubernetes namespace to deploy ArgoCD into"
  type        = string
}

# Required
variable "chart_version" {
  description = "Version of the ArgoCD Helm chart"
  type        = string
}

# Required
variable "homelab_domain" {
  description = "Domain name for the homelab environment"
  type        = string
}

# Optional
variable "argocd_subdomain" {
  description = "Subdomain for the ArgoCD service"
  type        = string
  default     = "argocd"
}

# Required
variable "gateway_name" {
  description = "Name of the Gateway resource"
  type        = string
}

# Required
variable "gateway_namespace" {
  description = "Namespace of the Gateway resource"
  type        = string
}

# Required
variable "gateway_listener_https" {
  description = "Listener name for wildcard HTTPS traffic"
  type        = string
}
