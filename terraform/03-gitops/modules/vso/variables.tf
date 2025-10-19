# Optional
variable "chart_namespace" {
  description = "The Kubernetes namespace to deploy VSO into"
  type        = string
  default     = "vault-secrets-operator-system"
}

# Required
variable "chart_version" {
  description = "Version of the VSO Helm chart"
  type        = string
}