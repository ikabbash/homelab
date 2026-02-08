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
      argocd_host          = var.argocd_host
      argocd_client_id     = var.argocd_client_id
      argocd_client_secret = var.argocd_client_secret
      argocd_issuer_url    = var.argocd_issuer_url
    })
  ]
}

resource "kubernetes_manifest" "argocd_http_route" {
  manifest = yamldecode(templatefile("${path.module}/templates/httproute.yaml.tftpl", {
    argocd_namespace       = var.chart_namespace
    argocd_host            = var.argocd_host
    gateway_name           = var.gateway_name
    gateway_namespace      = var.gateway_namespace
    gateway_listener_https = var.gateway_listener_https
  }))

  depends_on = [helm_release.argocd]
}
