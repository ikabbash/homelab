resource "kubernetes_manifest" "vso_connection" {
  manifest = yamldecode(templatefile("${path.module}/templates/connection.yaml.tftpl", {
    vso_connection_name = var.vso_connection_name
    vso_namespace       = var.vso_namespace
    vault_address       = var.vault_address
    vault_port          = var.vault_port
  }))
}

resource "kubernetes_manifest" "vso_auth_global" {
  manifest = yamldecode(templatefile("${path.module}/templates/auth-global.yaml.tftpl", {
    vso_connection_name  = var.vso_connection_name
    vso_namespace        = var.vso_namespace
    vso_bound_namespaces = var.vso_bound_namespaces
    vso_role_name        = var.vso_role_name
    kubernetes_auth_path = var.kubernetes_auth_path
    vso_audience         = var.vso_audience
    vso_service_account  = var.vso_service_account
  }))
}
