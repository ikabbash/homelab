resource "kubernetes_namespace_v1" "vault_namespace" {
  metadata {
    name = var.chart_namespace
    labels = {
      route-access = "vault"
    }
  }
}

# Certificate to create TLS secret for Vault
resource "kubernetes_manifest" "vault_certificate" {
  manifest = yamldecode(templatefile("${path.module}/templates/certificate.yaml.tftpl", {
    vault_certificate_name = var.vault_certificate_name
    vault_namespace        = var.chart_namespace
    vault_host             = var.vault_host
    cluster_issuer_name    = var.cluster_issuer_name
  }))
}

# HTTP route to redirect to HTTPS
resource "kubernetes_manifest" "vault_http_route" {
  manifest = yamldecode(templatefile("${path.module}/templates/httproute.yaml.tftpl", {
    vault_namespace       = var.chart_namespace
    vault_host            = var.vault_host
    gateway_name          = var.gateway_name
    gateway_namespace     = var.gateway_namespace
    gateway_listener_http = var.gateway_listener_http
  }))
}

# TLS Passthrough for Vault (end-to-end TLS)
resource "kubernetes_manifest" "vault_tls_route" {
  manifest = yamldecode(templatefile("${path.module}/templates/tlsroute.yaml.tftpl", {
    vault_namespace        = var.chart_namespace
    vault_host             = var.vault_host
    gateway_name           = var.gateway_name
    gateway_namespace      = var.gateway_namespace
    gateway_listener_vault = var.gateway_listener_vault
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
      chart_namespace        = var.chart_namespace
      vault_host             = var.vault_host
      vault_certificate_name = var.vault_certificate_name
      storage_class_name     = var.storage_class_name
      vault_storage_size     = var.vault_storage_size
      enable_monitoring      = var.enable_monitoring
    })
  ]

  depends_on = [kubernetes_manifest.vault_certificate]
}
