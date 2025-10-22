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

# Required
variable "vso_namespace" {
  description = "The namespace where VSO is deployed"
  type        = string
}

# Required
variable "vso_role_name" {
  description = "Name of the Kubernetes auth backend role for VSO"
  type        = string
}

# Required
variable "vso_service_account" {
  description = "VSO service account name for every namespace"
  type        = string
}

# Optional
variable "vso_auth_name" {
  description = "Name of the VSO Auth resource in ArgoCD's namespace"
  type        = string
  default     = "vso-auth"
}

# Required
variable "infra_kv_mount_path" {
  description = "Path of the KV-v2 secret mount for homelab infrastructure"
  type        = string
}