resource "kubernetes_namespace_v1" "rook_namespace" {
  metadata {
    name = var.chart_namespace
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "rook_ceph_operator" {
  name       = "rook-ceph-operator"
  repository = "https://charts.rook.io/release"
  chart      = "rook-ceph"
  version    = var.chart_version
  namespace  = var.chart_namespace
  skip_crds  = false

  values = [yamlencode({
    enableDiscoveryDaemon = true
    csi = {
      enableCephfsSnapshotter = true
      enableRBDSnapshotter    = true
      provisionerReplicas     = 1
    }
  })]

  depends_on = [kubernetes_namespace_v1.rook_namespace]
}

resource "helm_release" "rook_ceph_cluster" {
  name       = "rook-ceph-cluster"
  repository = "https://charts.rook.io/release"
  chart      = "rook-ceph-cluster"
  version    = var.chart_version
  namespace  = var.chart_namespace
  skip_crds  = false

  values = [
    templatefile("${path.module}/templates/cluster-values.yaml.tftpl", {
      rook_namespace = var.chart_namespace
    })
  ]

  depends_on = [helm_release.rook_ceph_operator, kubernetes_namespace_v1.rook_namespace]
}
