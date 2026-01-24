# Required
variable "chart_namespace" {
  description = "The Kubernetes namespace to deploy OpenEBS into"
  type        = string
}

# Required
variable "chart_version" {
  description = "OpenEBS Helm chart version"
  type        = string
}

# Optional
variable "host_storage_path" {
  description = "OpenEBS Local Storage host path"
  type        = string
  default     = "/var/mnt/homelab"
}

# Optional
variable "host_storage_class_name" {
  description = "Name of the StorageClass created for OpenEBS hostpath volumes"
  type        = string
  default     = "openebs-hostpath"
}