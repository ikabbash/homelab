resource "kubernetes_manifest" "cluster_issuer" {
  manifest = yamldecode(templatefile("${path.module}/templates/cluster-issuer.yaml.tftpl", {
    cluster_issuer_name        = var.cluster_issuer_name
    letsencrypt_email          = var.letsencrypt_email
    cluster_issuer_secret_name = var.cluster_issuer_secret_name
  }))
}

resource "kubernetes_namespace_v1" "gateway_namespace" {
  metadata {
    name = var.gateway_namespace
  }
}

resource "kubernetes_manifest" "gateway" {
  manifest = yamldecode(templatefile("${path.module}/templates/gateway.yaml.tftpl", {
    gateway_name           = var.gateway_name
    gateway_namespace      = var.gateway_namespace
    cluster_issuer_name    = var.cluster_issuer_name
    gateway_external_ip    = var.gateway_external_ip
    homelab_domain         = var.homelab_domain
    gateway_listener_http  = var.gateway_listener_http
    gateway_listener_https = var.gateway_listener_https
  }))

  depends_on = [kubernetes_namespace_v1.gateway_namespace, kubernetes_manifest.cluster_issuer]
}

resource "kubernetes_manifest" "vault_gateway" {
  manifest = yamldecode(templatefile("${path.module}/templates/vault-gateway.yaml.tftpl", {
    vault_gateway_name        = var.vault_gateway_name
    gateway_namespace         = var.gateway_namespace
    vault_gateway_external_ip = var.vault_gateway_external_ip
    vault_host                = var.vault_host
    gateway_listener_http     = var.gateway_listener_http
    gateway_listener_vault    = var.gateway_listener_vault
  }))

  depends_on = [kubernetes_namespace_v1.gateway_namespace]
}

resource "kubernetes_manifest" "cilium_lb_ip_pool" {
  manifest = yamldecode(templatefile("${path.module}/templates/lb-ipam.yaml.tftpl", {
    pool_name            = "homelab-gw-ip-pool"
    pool_ip              = var.gateway_external_ip
    gateway_namespace    = var.gateway_namespace
    service_gateway_name = var.gateway_name
  }))

  depends_on = [kubernetes_namespace_v1.gateway_namespace]
}

resource "kubernetes_manifest" "cilium_vault_lb_ip_pool" {
  manifest = yamldecode(templatefile("${path.module}/templates/lb-ipam.yaml.tftpl", {
    pool_name            = "vault-gw-ip-pool"
    pool_ip              = var.vault_gateway_external_ip
    gateway_namespace    = var.gateway_namespace
    service_gateway_name = var.vault_gateway_name
  }))

  depends_on = [kubernetes_namespace_v1.gateway_namespace]
}

resource "kubernetes_manifest" "cilium_l2_announcement_policy" {
  manifest = yamldecode(templatefile("${path.module}/templates/l2-policy.yaml.tftpl", {
    gateway_namespace = var.gateway_namespace
  }))
}