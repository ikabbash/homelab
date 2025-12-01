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
variable "lb_external_ip" {
  description = "Load balancer external IP for either Ingress Controller or Gateway API"
  type        = string
}

# Required
variable "gateway_api_version" {
  description = "Kubernetes Gateway API CRDs version"
  type        = string
}

# Required
variable "gateway_name" {
  description = "Name of the main Gateway for all namespaces"
  type        = string
}