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
