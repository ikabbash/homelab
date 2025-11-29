# Optional
variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

# Optional
variable "homelab_data_path" {
  description = "Base path for homelab data storage"
  type        = string
  default     = "/var/mnt/homelab"
}