resource "kubernetes_manifest" "cilium_lb_ip_pool" {
  manifest = yamldecode(templatefile("${path.module}/templates/lb-ipam.yaml.tftpl", {
    lb_external_ip    = var.lb_external_ip
    gateway_namespace = var.gateway_namespace
    gateway_name      = var.gateway_name
  }))
}

resource "kubernetes_manifest" "cilium_l2_announcement_policy" {
  manifest = yamldecode(templatefile("${path.module}/templates/l2-policy.yaml.tftpl", {
    gateway_namespace = var.gateway_namespace
    gateway_name      = var.gateway_name
  }))
}