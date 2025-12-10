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

# Required
variable "vault_address" {
  description = "Complete domain name where the Vault service will be accessible"
  type        = string
}

# Required
variable "gateway_external_ip" {
  description = "Load balancer external IP for Gateway API"
  type        = string
}
