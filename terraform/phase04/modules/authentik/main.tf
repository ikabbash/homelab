resource "random_password" "authentik_secret_key" {
  length  = 50
  special = true
}

resource "kubernetes_persistent_volume_claim_v1" "authentik_media_pvc" {
  metadata {
    name      = var.authentik_media_pvc_name
    namespace = var.chart_namespace
  }
  wait_until_bound = false
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class_name
    resources {
      requests = {
        storage = var.authentik_media_storage_size
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "authentik_templates_pvc" {
  metadata {
    name      = var.authentik_templates_pvc_name
    namespace = var.chart_namespace
  }
  wait_until_bound = false
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class_name
    resources {
      requests = {
        storage = var.authentik_templates_storage_size
      }
    }
  }
}

resource "kubernetes_manifest" "authentik_smtp_secret" {
  manifest = yamldecode(
    templatefile(
      "${path.module}/templates/static-secret.yaml.tftpl",
      {
        authentik_namespace = var.chart_namespace
        smtp_secret_name    = var.authentik_smtp_secret_name
        vso_auth_name       = var.vso_auth_name
      }
    )
  )
}

# Deploy Vault 
resource "helm_release" "authentik" {
  name       = "authentik"
  repository = "https://charts.goauthentik.io"
  chart      = "authentik"
  namespace  = var.chart_namespace
  version    = var.chart_version
  skip_crds  = false

  values = [
    templatefile("${path.module}/templates/values.yaml.tftpl", {
      secret_key           = random_password.authentik_secret_key.result
      namespace            = var.chart_namespace
      media_pvc_name       = var.authentik_media_pvc_name
      templates_pvc_name   = var.authentik_templates_pvc_name
      postgres_secret_name = var.postgres_secret_name
      smtp_secret_name     = var.authentik_smtp_secret_name
      postgres_host        = var.postgres_host
    })
  ]

  depends_on = [
    kubernetes_persistent_volume_claim_v1.authentik_media_pvc,
    kubernetes_persistent_volume_claim_v1.authentik_templates_pvc,
    kubernetes_manifest.authentik_smtp_secret
  ]
}

resource "kubernetes_manifest" "authentik_http_route" {
  manifest = yamldecode(templatefile("${path.module}/templates/httproute.yaml.tftpl", {
    authentik_namespace    = var.chart_namespace
    authentik_address      = "${var.authentik_subdomain}.${var.homelab_domain}"
    gateway_name           = var.gateway_name
    gateway_namespace      = var.gateway_namespace
    gateway_listener_https = var.gateway_listener_https
  }))
}