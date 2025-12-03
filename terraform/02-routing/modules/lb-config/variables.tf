# Required
variable "gateway_name" {
  description = "Name of the main Gateway for all namespaces"
  type        = string
}

# Required
variable "gateway_namespace" {
  description = "Gateway resources' namespace"
  type        = string
}

# Required
variable "lb_external_ip" {
  description = "Load balancer external IP for either Ingress Controller or Gateway API"
  type        = string
}