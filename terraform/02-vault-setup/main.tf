terraform {
  required_version = ">= 1.0"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
}

resource "vault_mount" "homelab_infra_kv" {
  path        = "homelab/infra/kv-secret"
  type        = "kv-v2"
  description = "KV-v2 secret mount for homelab infrastructure"
}

resource "vault_mount" "homelab_apps_kv" {
  path        = "homelab/apps/kv-secret"
  type        = "kv-v2"
  description = "KV-v2 secret mount for homelab applications"
}

resource "vault_policy" "vso_policy" {
  name   = "vso-global-policy"
  policy = file("${var.policy_directory}/vso-global.hcl")
}

resource "vault_auth_backend" "vso_kubernetes" {
  type        = "kubernetes"
  path        = "kubernetes/vso"
  description = "auth method for VSO"
}

resource "vault_kubernetes_auth_backend_config" "vso_config" {
  backend         = vault_auth_backend.vso_kubernetes.path
  kubernetes_host = var.kubernetes_host
  depends_on      = [vault_auth_backend.vso_kubernetes]
}

resource "vault_kubernetes_auth_backend_role" "vso_role" {
  backend                          = vault_auth_backend.vso_kubernetes.path
  role_name                        = "default"
  bound_service_account_names      = ["vso-sa"]
  bound_service_account_namespaces = ["argocd"]
  token_ttl                        = 3600  # 1 hour
  token_max_ttl                    = 14400 # 4 hours
  token_policies                   = [vault_policy.vso_policy.name]
  token_no_default_policy          = false
  audience                         = "vault"
  depends_on                       = [vault_policy.vso_policy, vault_kubernetes_auth_backend_config.vso_config]
}