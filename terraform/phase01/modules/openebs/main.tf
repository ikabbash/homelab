resource "kubernetes_namespace_v1" "openebs_namespace" {
  metadata {
    name = var.chart_namespace
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "openebs" {
  name       = "openebs"
  repository = "https://openebs.github.io/openebs"
  chart      = "openebs"
  version    = var.chart_version
  namespace  = var.chart_namespace
  skip_crds  = false

  values = [
    templatefile("${path.module}/templates/values.yaml.tftpl", {
      host_storage_path       = var.host_storage_path
      host_storage_class_name = var.host_storage_class_name
    })
  ]

  depends_on = [kubernetes_namespace_v1.openebs_namespace]
}