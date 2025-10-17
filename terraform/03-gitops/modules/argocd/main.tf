resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = var.chart_namespace
  version          = var.chart_version
  skip_crds        = true
  create_namespace = true

  values = [
    templatefile("${path.module}/templates/values.yaml.tftpl", {
      domain      = "${var.argocd_subdomain}.${var.homelab_domain}"
      issuer_name = var.cluster_issuer_name
    })
  ]
}