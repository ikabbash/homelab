resource "helm_release" "vso" {
  name             = "vault-secrets-operator"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault-secrets-operator"
  namespace        = var.chart_namespace
  version          = var.chart_version
  skip_crds        = false
  create_namespace = true

  values = [
    templatefile("${path.module}/templates/values.yaml.tftpl", {
      vault_host        = var.vault_host
      enable_monitoring = var.enable_monitoring
    })
  ]
}

resource "kubernetes_manifest" "vso_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/templates/networkpolicy.yaml.tftpl", {
    vso_namespace   = var.chart_namespace
    vault_namespace = var.vault_namespace
  }))
  field_manager {
    name            = "terraform"
    force_conflicts = true
  }
}