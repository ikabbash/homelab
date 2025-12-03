# Optional
variable "gateway_name" {
  description = "Name of the Gateway resource"
  type        = string
  default     = "homelab-gw"
}

# Optional
variable "gateway_namespace" {
  description = "Namespace of the Gateway resource"
  type        = string
  default     = "cilium-gateway"
}

# Required
variable "lb_external_ip" {
  description = "Load balancer external IP for either Ingress Controller or Gateway API"
  type        = string
}

# Required
variable "homelab_domain" {
  description = "Domain name for the homelab environment"
  type        = string
}

# Required
variable "cluster_issuer_name" {
  description = "Cert Manager's Cluster Issuer name"
  type        = string
}