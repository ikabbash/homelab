data "kubernetes_nodes" "all" {}
# Temporary workaround to resolve Vault's TLS with the domain
locals {
  node_internal_ips = [
    for node in data.kubernetes_nodes.all.nodes : [
      for address in node.status[0].addresses :
      address.address if address.type == "InternalIP"
    ][0]
  ]
}

resource "helm_release" "vso" {
  name             = "vault-secrets-operator"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault-secrets-operator"
  namespace        = var.chart_namespace
  version          = var.chart_version
  skip_crds        = true
  create_namespace = true

  values = [
    templatefile("${path.module}/templates/values.yaml.tftpl", {
      node_ips   = local.node_internal_ips
      vault_host = var.vault_address
    })
  ]
}