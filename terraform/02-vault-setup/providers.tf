provider "vault" {
  address = "https://${var.vault_address}:${var.vault_port}"

  auth_login {
    path = "auth/approle/login"
    parameters = {
      role_id   = var.login_approle_role_id
      secret_id = var.login_approle_secret_id
    }
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}