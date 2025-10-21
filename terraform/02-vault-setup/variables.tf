variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

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