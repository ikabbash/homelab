variable "login_approle_role_id" {
  description = "Vault AppRole Role ID for Terraform authentication"
  type        = string
  sensitive   = true
}

variable "login_approle_secret_id" {
  description = "Vault AppRole Secret ID for Terraform authentication"
  type        = string
  sensitive   = true
}

variable "vault_address" {
  description = "Address of the Vault server used for setup"
  type        = string
}

variable "vault_port" {
  description = "Port number on which the Vault server is running."
  type        = number
}

variable "kubernetes_host" {
  description = "Kubernetes API host"
  type        = string
  default     = "https://kubernetes.default.svc:443"
}

variable "policy_directory" {
  description = "Directory containing HCL policy files"
  type        = string
  default     = "./policies"
}