# Required
variable "chart_namespace" {
  description = "The Kubernetes namespace to deploy Argo CD into"
  type        = string
}

# Required
variable "chart_version" {
  description = "Version of the Argo CD Helm chart"
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
variable "argocd_host" {
  description = "Argo CD service hostname where Argo CD will be accessible"
  type        = string
}

# Required
variable "argocd_client_id" {
  description = "OAuth2 Client ID for Argo CD"
  type        = string
}

# Required
variable "argocd_client_secret" {
  description = "OAuth2 Client Secret for Argo CD"
  type        = string
}

# Required
variable "argocd_issuer_url" {
  description = "OIDC Issuer URL for Argo CD DEX configuration"
  type        = string
}

# Required
variable "enable_monitoring" {
  description = "Enables monitoring integration. Requires Prometheus Operator to be deployed first"
  type        = bool
}