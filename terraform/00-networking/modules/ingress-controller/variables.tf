# Required
variable "chart_version" {
  description = "nginx-ingress Helm chart version"
  type        = string
}

# Required
variable "chart_namespace" {
  description = "The Kubernetes namespace to deploy nginx-ingress into"
  type        = string
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