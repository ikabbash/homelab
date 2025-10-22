resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.chart_namespace
  }
}

resource "kubernetes_manifest" "vso_auth" {
  manifest = yamldecode(templatefile("${path.module}/templates/auth.yaml.tftpl", {
    auth_name             = var.vso_auth_name
    namespace             = var.chart_namespace
    role                  = var.vso_role_name
    service_account       = var.vso_service_account
    auth_global_namespace = var.vso_namespace
  }))

  depends_on = [kubernetes_namespace.argocd]
}

resource "kubernetes_service_account" "vso_sa" {
  metadata {
    name      = var.vso_service_account
    namespace = var.chart_namespace
  }

  depends_on = [kubernetes_namespace.argocd]
}

resource "kubernetes_manifest" "vso_static_secret" {
  manifest = yamldecode(templatefile("${path.module}/templates/static-secret.yaml.tftpl", {
    namespace = var.chart_namespace
    auth_ref  = var.vso_auth_name
    kv_path   = var.infra_kv_mount_path
  }))

  depends_on = [kubernetes_manifest.vso_auth]
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = var.chart_namespace
  version    = var.chart_version
  skip_crds  = true

  values = [
    templatefile("${path.module}/templates/values.yaml.tftpl", {
      domain      = "${var.argocd_subdomain}.${var.homelab_domain}"
      issuer_name = var.cluster_issuer_name
    })
  ]

  depends_on = [kubernetes_manifest.vso_static_secret]
}