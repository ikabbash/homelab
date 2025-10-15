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