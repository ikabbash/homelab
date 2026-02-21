# Optional
variable "kubernetes_host" {
  description = "Kubernetes API host"
  type        = string
  default     = "https://kubernetes.default.svc:443"
}

# Optional
variable "policy_directory" {
  description = "Directory containing HCL policy files"
  type        = string
  default     = "./modules/vault-configs/policies"
}

# Required
variable "audit_file_path" {
  description = "Mount path where the Vault audit log file will be stored"
  type        = string
}