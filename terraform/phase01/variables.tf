# Optional
variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

# Required
variable "cluster_service_host" {
  description = "Control plane API IP or VIP for Cilium"
  type        = string
}
