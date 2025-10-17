# Optional
variable "chart_namespace" {
  description = "The Kubernetes namespace to deploy ArgoCD into"
  type        = string
  default     = "argocd"
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
variable "cluster_issuer_name" {
  description = "Cert Manager's Cluster Issuer name"
  type        = string
}