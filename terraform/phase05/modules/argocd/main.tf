locals {
  argocd_address = "${var.argocd_subdomain}.${var.homelab_domain}"
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = var.chart_namespace
  version          = var.chart_version
  skip_crds        = false
  create_namespace = true

  values = [
    templatefile("${path.module}/templates/values.yaml.tftpl", {
      argocd_address = local.argocd_address
    })
  ]
}

resource "kubernetes_manifest" "argocd_http_route" {
  manifest = yamldecode(templatefile("${path.module}/templates/httproute.yaml.tftpl", {
    argocd_namespace       = var.chart_namespace
    argocd_address         = local.argocd_address
    gateway_name           = var.gateway_name
    gateway_namespace      = var.gateway_namespace
    gateway_listener_https = var.gateway_listener_https
  }))

  depends_on = [helm_release.argocd]
}
