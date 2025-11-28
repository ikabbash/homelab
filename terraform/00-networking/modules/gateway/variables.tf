# Required
variable "gateway_name" {
  description = "Name of the main Gateway for all namespaces"
  type        = string
}

# Required
variable "gateway_namespace" {
  description = "Gateway resources' namespace"
  type        = string
  default     = "cilium-gateway"
}

# Required
variable "lb_external_ip" {
  description = "Load balancer external IP for either Ingress Controller or Gateway API"
  type        = string
}

# Optional
variable "l2_policy_name" {
  description = "Cilium L2 policy name for both Ingress Controller and Gateway API"
  type        = string
  default     = "cluster-entrypoint-l2-policy"
}