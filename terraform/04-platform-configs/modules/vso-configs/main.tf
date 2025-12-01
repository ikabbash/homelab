resource "kubernetes_manifest" "vso_connection" {
  manifest = yamldecode(templatefile("${path.module}/templates/connection.yaml.tftpl", {
    connection = var.vso_connection_name
    namespace  = var.vso_namespace
    domain     = var.vault_address
    port       = var.vault_port
  }))
}

resource "kubernetes_manifest" "vso_auth_global" {
  manifest = yamldecode(templatefile("${path.module}/templates/auth-global.yaml.tftpl", {
    connection = var.vso_connection_name
    namespace  = var.vso_namespace
    bound_namespaces = var.vso_bound_namespaces
    role = var.vso_role_name
    path = var.kubernetes_auth_path
    audience = var.vso_audience
    service_account = var.vso_service_account
  }))
}