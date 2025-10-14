# Required
variable "login_approle_role_id" {
  description = "Vault AppRole Role ID for Terraform authentication"
  type        = string
  sensitive   = true
}

# Required
variable "login_approle_secret_id" {
  description = "Vault AppRole Secret ID for Terraform authentication"
  type        = string
  sensitive   = true
}

# Required
variable "vault_address" {
  description = "Address of the Vault server used for setup"
  type        = string
}

# Required
variable "vault_port" {
  description = "Port number on which the Vault server is running."
  type        = number
}