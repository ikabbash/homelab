# Optional
variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "gateway_api_version" {
  description = "Kubernetes Gateway API CRDs version"
  type        = string
  default     = "v1.2.0"
}

variable "gateway_name" {
  description = "Name of the main Gateway for all namespaces"
  type        = string
  default     = "homelab-gw"
}

variable "cilium_chart_version" {
  description = "Cilium Helm chart version"
  type        = string
  default     = "1.18.4"
}

variable "cilium_chart_namespace" {
  description = "The Kubernetes namespace to deploy Cilium into"
  type        = string
  default     = "kube-system"
}

variable "cilium_service_host" {
  description = "Control plane API IP or VIP for Cilium"
  type        = string
}

variable "cilium_l2_policy_name" {
  description = "Cilium L2 policy name for both Ingress Controller and Gateway API"
  type        = string
  default     = "cluster-entrypoint-l2-policy"
}

variable "lb_service_external_ip" {
  description = "Load balancer external IP for either Ingress Controller or Gateway API"
  type        = string
}

# variable "ingress_controller_chart_version" {
#   description = "nginx-ingress Helm chart version"
#   type        = string
#   default     = "2.3.1"
# }

# variable "ingress_controller_chart_namespace" {
#   description = "The Kubernetes namespace to deploy nginx-ingress into"
#   type        = string
#   default     = "nginx-ingress"
# }