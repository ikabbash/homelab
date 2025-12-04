# Optional
variable "kubernetes_host" {
  description = "Kubernetes API host"
  type        = string
  default     = "https://kubernetes.default.svc:443"
}

# Required
variable "vault_port" {
  description = "Port number on which the Vault server is running."
  type        = number
}

# Optional
variable "policy_directory" {
  description = "Directory containing HCL policy files"
  type        = string
  default     = "./modules/vault-configs/policies"
}