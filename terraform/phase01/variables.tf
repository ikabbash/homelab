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

# Required
variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS validation"
  type        = string
  sensitive   = true
}

# Required
variable "enable_monitoring" {
  description = "Enables monitoring integration. Requires Prometheus Operator to be deployed first"
  type        = bool
}