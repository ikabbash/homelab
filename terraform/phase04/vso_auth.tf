data "terraform_remote_state" "phase03" {
  backend = "local"
  config = {
    path = "../phase03/terraform.tfstate"
  }
}

locals {
  phase03 = data.terraform_remote_state.phase03.outputs
}

resource "kubernetes_manifest" "vso_auth" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultAuth"
    metadata = {
      name      = var.vso_auth_name
      namespace = var.authentik_namespace
    }
    spec = {
      kubernetes = {
        role           = local.phase03.vso_role_name
        serviceAccount = local.phase03.vso_service_account
      }
      vaultAuthGlobalRef = {
        allowDefault = true
        namespace    = local.phase03.vso_namespace
      }
    }
  }
  depends_on = [kubernetes_namespace_v1.authentik_namespace]
}

resource "kubernetes_service_account" "vso_sa" {
  metadata {
    name      = local.phase03.vso_service_account
    namespace = var.authentik_namespace
  }

  depends_on = [kubernetes_namespace_v1.authentik_namespace]
}