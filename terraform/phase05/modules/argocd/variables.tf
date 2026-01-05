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

# Required
variable "argocd_address" {
  description = "Complete domain name for ArgoCD"
  type        = string
}

# Required
variable "argocd_client_id" {
  description = "OAuth2 Client ID for ArgoCD"
  type        = string
}

# Required
variable "argocd_client_secret" {
  description = "OAuth2 Client Secret for ArgoCD"
  type        = string
}

# Required
variable "argocd_issuer_url" {
  description = "OIDC Issuer URL for ArgoCD DEX configuration"
  type        = string
}