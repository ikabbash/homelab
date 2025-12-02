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