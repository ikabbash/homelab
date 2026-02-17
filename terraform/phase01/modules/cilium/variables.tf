# Required
variable "chart_version" {
  description = "Cilium Helm chart version"
  type        = string
}

# Required
variable "chart_namespace" {
  description = "The Kubernetes namespace to deploy Cilium into"
  type        = string
}

# Required
variable "cluster_service_host" {
  description = "Control plane API IP or VIP for Cilium"
  type        = string
}

# Required
variable "gateway_api_version" {
  description = "Kubernetes Gateway API CRDs version"
  type        = string
}

# Required
variable "enable_monitoring" {
  description = "Enables monitoring integration. Requires Prometheus Operator to be deployed first"
  type        = bool
}