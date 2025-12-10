resource "kubernetes_namespace_v1" "vault_namespace" {
  metadata {
    name = var.chart_namespace
    labels = {
      route-access = "vault"
    }
  }
}

resource "kubernetes_persistent_volume_v1" "vault_pv" {
  metadata {
    name = var.vault_pv_name
  }

  spec {
    capacity = {
      storage = var.vault_storage_size
    }
    access_modes                     = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Retain"
    persistent_volume_source {
      host_path {
        path = "${var.homelab_data_path}/vault"
        type = "DirectoryOrCreate"
      }
    }
    claim_ref {
      namespace = var.chart_namespace
      name      = var.vault_pvc_name
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "vault_pvc" {
  metadata {
    name      = var.vault_pvc_name
    namespace = var.chart_namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.vault_storage_size
      }
    }
    volume_name = kubernetes_persistent_volume_v1.vault_pv.metadata[0].name
  }
  depends_on = [kubernetes_namespace_v1.vault_namespace]
}

# Certificate to create TLS secret for Vault
resource "kubernetes_manifest" "vault_certificate" {
  manifest = yamldecode(templatefile("${path.module}/templates/certificate.yaml.tftpl", {
    vault_certificate_name = var.vault_certificate_name
    vault_namespace        = var.chart_namespace
    vault_address          = var.vault_address
    cluster_issuer_name    = var.cluster_issuer_name
  }))
}

# HTTP route to redirect to HTTPS
resource "kubernetes_manifest" "vault_http_route" {
  manifest = yamldecode(templatefile("${path.module}/templates/httproute.yaml.tftpl", {
    vault_namespace       = var.chart_namespace
    vault_address         = var.vault_address
    gateway_name          = var.gateway_name
    gateway_namespace     = var.gateway_namespace
    gateway_listener_http = var.gateway_listener_http
  }))
}

# TLS Passthrough for Vault (end-to-end TLS)
resource "kubernetes_manifest" "vault_tls_route" {
  manifest = yamldecode(templatefile("${path.module}/templates/tlsroute.yaml.tftpl", {
    vault_namespace        = var.chart_namespace
    vault_address          = var.vault_address
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
      vault_address          = var.vault_address
      vault_certificate_name = var.vault_certificate_name
      pvc_name               = var.vault_pvc_name
    })
  ]

  depends_on = [
    kubernetes_persistent_volume_claim_v1.vault_pvc,
    kubernetes_manifest.vault_certificate
  ]
}
