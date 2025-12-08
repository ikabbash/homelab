# Deploy CloudnativePG Operator
resource "helm_release" "cnpg_operator" {
  name             = "cnpg"
  repository       = "https://cloudnative-pg.github.io/charts"
  chart            = "cloudnative-pg"
  namespace        = var.chart_namespace
  version          = var.chart_version
  skip_crds        = false
  create_namespace = true
}
