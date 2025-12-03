resource "kubernetes_namespace_v1" "gateway" {
  metadata {
    name = var.gateway_namespace
  }
}

resource "kubernetes_manifest" "gateway" {
  manifest = yamldecode(templatefile("${path.module}/templates/gateway.yaml.tftpl", {
    gateway_name        = var.gateway_name
    gateway_namespace   = var.gateway_namespace
    cluster_issuer_name = var.cluster_issuer_name
    lb_external_ip      = var.lb_external_ip
    homelab_domain      = var.homelab_domain
  }))

  depends_on = [kubernetes_namespace_v1.gateway]
}