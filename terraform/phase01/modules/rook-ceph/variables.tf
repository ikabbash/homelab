# Required
variable "chart_namespace" {
  description = "The Kubernetes namespace to deploy Rook operator and cluster into"
  type        = string
}

# Required
variable "chart_version" {
  description = "Rook Ceph Helm charts version (both operator and cluster)"
  type        = string
}