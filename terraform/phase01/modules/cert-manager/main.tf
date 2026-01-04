resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = var.chart_namespace
  create_namespace = true
  version          = var.chart_version
  skip_crds        = false

  values = [
    templatefile("${path.module}/templates/values.yaml.tftpl", {
      namespace = var.chart_namespace
    })
  ]
}

resource "kubernetes_secret_v1" "cluster_issuer_secret_name" {
  metadata {
    name      = "cloudflare-api-token-secret"
    namespace = var.chart_namespace
  }

  data = {
    api-token = var.cloudflare_api_token
  }

  depends_on = [helm_release.cert_manager]
}