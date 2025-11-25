# Optional
variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "cilium_chart_version" {
  description = ""
  type        = string
  default     = "1.18.4"
}

variable "cilium_chart_namespace" {
  description = ""
  type        = string
  default     = "kube-system"
}

variable "cilium_service_host" {
  description = ""
  type        = string
}

variable "ingress_controller_chart_version" {
  description = ""
  type        = string
  default     = "2.3.1"
}

variable "ingress_controller_chart_namespace" {
  description = ""
  type        = string
  default     = "nginx-ingress"
}

variable "ingress_controller_loadbalancer" {
  description = ""
  type        = string
}