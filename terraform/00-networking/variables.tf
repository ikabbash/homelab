# Optional
variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
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

variable "ingress_controller_chart_version" {
  description = "nginx-ingress Helm chart version"
  type        = string
  default     = "2.3.1"
}

variable "ingress_controller_chart_namespace" {
  description = "The Kubernetes namespace to deploy nginx-ingress into"
  type        = string
  default     = "nginx-ingress"
}

variable "ingress_controller_loadbalancer" {
  description = "Load balancer address for the ingress controller"
  type        = string
}