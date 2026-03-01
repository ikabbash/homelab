resource "kubernetes_namespace_v1" "vault_namespace" {
  metadata {
    name = var.chart_namespace
  }
}

# Self-signed issuer
resource "kubernetes_manifest" "vault_selfsigned_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "vault-selfsigned-issuer"
      namespace = var.chart_namespace
    }
    spec = {
      selfSigned = {}
    }
  }
}

# Certificate to CA
resource "kubernetes_manifest" "vault_ca_certificate" {
  manifest = yamldecode(templatefile("${path.module}/templates/certificate-ca.yaml.tftpl", {
    vault_namespace = var.chart_namespace
    issuer_name     = kubernetes_manifest.vault_selfsigned_issuer.manifest.metadata.name
    secret_name     = var.vault_ca_secret_name
  }))
}

resource "kubernetes_manifest" "vault_ca_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "vault-ca-issuer"
      namespace = var.chart_namespace
    }
    spec = {
      ca = {
        secretName = var.vault_ca_secret_name
      }
    }
  }

  depends_on = [kubernetes_manifest.vault_ca_certificate]
}

# Vault TLS
resource "kubernetes_manifest" "vault_certificate" {
  manifest = yamldecode(templatefile("${path.module}/templates/certificate-vault.yaml.tftpl", {
    vault_namespace = var.chart_namespace
    issuer_name     = kubernetes_manifest.vault_selfsigned_issuer.manifest.metadata.name
    vault_host      = var.vault_host
    secret_name     = var.vault_tls_secret_name
  }))
}

# Deploy Vault 
resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  namespace  = var.chart_namespace
  version    = var.chart_version
  skip_crds  = false

  values = [
    templatefile("${path.module}/templates/values.yaml.tftpl", {
      chart_namespace       = var.chart_namespace
      vault_host            = var.vault_host
      vault_tls_secret_name = var.vault_tls_secret_name
      vault_ca_secret_name  = var.vault_ca_secret_name
      storage_class_name    = var.storage_class_name
      storage_size          = var.vault_storage_size
      audit_storage_size    = var.vault_audit_storage_size
      audit_file_path       = var.vault_audit_file_path
      enable_monitoring     = var.enable_monitoring
    })
  ]

  depends_on = [kubernetes_manifest.vault_certificate]
}

# logrotate config for Vault audit file CronJob
resource "kubernetes_config_map_v1" "vault_audit_logrotate_config" {
  metadata {
    name      = "vault-audit-logrotate-config"
    namespace = var.chart_namespace
  }

  data = {
    "vault-audit" = <<-EOT
      ${var.vault_audit_file_path}/audit.log {
          weekly
          rotate 4
          compress
          delaycompress
          missingok
          notifempty
          copytruncate
          dateext
          dateformat -%Y-%m-%d
      }
    EOT
  }
}

# Vault audit file rotation CronJob
resource "kubernetes_manifest" "vault_audit_logrotate_cronjob" {
  manifest = yamldecode(templatefile("${path.module}/templates/cronjob.yaml.tftpl", {
    vault_namespace = var.chart_namespace
    audit_file_path = var.vault_audit_file_path
  }))

  depends_on = [helm_release.vault, kubernetes_config_map_v1.vault_audit_logrotate_config]
}