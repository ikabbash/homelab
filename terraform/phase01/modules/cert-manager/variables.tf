# Required
variable "chart_namespace" {
  description = "The Kubernetes namespace to deploy cert-manager into"
  type        = string
}

# Required
variable "chart_version" {
  description = "cert-manager Helm chart version"
  type        = string
}

# Required
variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS validation"
  type        = string
  sensitive   = true
}