# Required
variable "homelab_mount" {
  description = "Base path for homelab volume"
  type        = string
}

# Optional
variable "namespace" {
  description = "Base path for homelab volume"
  type        = string
  default     = "dirs-init"
}