locals {
  ip_pool_name = "${var.gateway_name}-ip-pool"
  cilium_gateway_manifest = templatefile("${path.module}/templates/gateway.yaml.tftpl", {
    gateway_name      = var.gateway_name
    gateway_namespace = var.gateway_namespace
    loadbalancer_ip   = var.lb_external_ip
    ip_pool_name      = local.ip_pool_name
    homelab_domain    = var.homelab_domain
    cluster_issuer    = var.cluster_issuer_name
  })

  cilium_l2_policy_manifest = templatefile("${path.module}/templates/l2policy.yaml.tftpl", {
    gateway_name      = var.gateway_name
    gateway_namespace = var.gateway_namespace
    policy_name       = var.l2_policy_name
  })
}

resource "kubernetes_namespace" "gateway_namespace" {
  metadata {
    name = var.gateway_namespace
  }
}

# Cilum LB IP Pool and Gateway
resource "null_resource" "cilium_gateway" {
  triggers = {
    gateway_name      = var.gateway_name
    gateway_namespace = var.gateway_namespace
    loadbalancer_ip   = var.lb_external_ip
    ip_pool_name      = local.ip_pool_name
    homelab_domain    = var.homelab_domain
    cluster_issuer    = var.cluster_issuer_name
    manifest_content  = local.cilium_gateway_manifest
  }

  provisioner "local-exec" {
    command = <<-EOT
      cat <<EOF | kubectl apply -f -
      ${local.cilium_gateway_manifest}
      EOF
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl delete gateway -n ${self.triggers.gateway_namespace} ${self.triggers.gateway_name} --ignore-not-found=true
      kubectl delete ciliumloadbalancerippool -n ${self.triggers.gateway_namespace} ${self.triggers.ip_pool_name} --ignore-not-found=true
    EOT
  }

  depends_on = [kubernetes_namespace.gateway_namespace]
}

# L2 Announcement Policy
resource "null_resource" "cilium_l2_policy" {
  triggers = {
    gateway_name      = var.gateway_name
    gateway_namespace = var.gateway_namespace
    policy_name       = var.l2_policy_name
    manifest_content  = local.cilium_l2_policy_manifest
  }

  provisioner "local-exec" {
    command = <<-EOT
      cat <<EOF | kubectl apply -f -
      ${local.cilium_l2_policy_manifest}
      EOF
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete ciliuml2announcementpolicy -n ${self.triggers.gateway_namespace} ${self.triggers.policy_name} --ignore-not-found=true"
  }
}