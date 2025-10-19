data "terraform_remote_state" "core_services" {
  backend = "local"
  config = {
    path = "../01-core-services/terraform.tfstate"
  }
}

data "terraform_remote_state" "vault_setup" {
  backend = "local"
  config = {
    path = "../02-vault-setup/terraform.tfstate"
  }
}

# locals {
#   connection_manifest = templatefile("${path.module}/templates/connection.yaml.tftpl", {
#     namespace = var.chart_namespace
#     domain    = data.terraform_remote_state.core_services.outputs.vault_address
#     port      = data.terraform_remote_state.vault_setup.outputs.vault_port
#   })

#   auth_manifest = templatefile("${path.module}/templates/auth-global.yaml.tftpl", {
#     namespace       = var.chart_namespace
#     path            = data.terraform_remote_state.vault_setup.outputs.kubernetes_auth_path
#     role            = data.terraform_remote_state.vault_setup.outputs.vso_role_name
#     bound_namespaces = join(",", data.terraform_remote_state.vault_setup.outputs.vso_bound_namespaces)
#     audience        = data.terraform_remote_state.vault_setup.outputs.vso_audience
#     service_account = data.terraform_remote_state.vault_setup.outputs.vso_service_account
#   })
# }

resource "helm_release" "vso" {
  name             = "vault-secrets-operator"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault-secrets-operator"
  namespace        = var.chart_namespace
  version          = var.chart_version
  skip_crds        = true
  create_namespace = true

  values = [file("${path.module}/templates/values.yaml.tftpl")]

  # values = [
  #   templatefile("${path.module}/templates/values.yaml.tftpl", {
  #     key1 = var.var1
  #   })
  # ]
}


# resource "null_resource" "vso_connection" {
#   triggers = {
#     namespace = var.chart_namespace
#     domain    = data.terraform_remote_state.core_services.outputs.vault_address
#     port      = data.terraform_remote_state.vault_setup.outputs.vault_port
#   }

#   provisioner "local-exec" {
#     command = "echo '${local.connection_manifest}' | kubectl apply -f -"
#   }

#   provisioner "local-exec" {
#     when    = destroy
#     command = "kubectl delete certificate ${self.triggers.secret_name} -n ${self.triggers.namespace} --ignore-not-found=true"
#   }

#   depends_on = [helm_release.vso]
# }

# resource "null_resource" "vso_auth" {
#   triggers = {
#     namespace       = var.chart_namespace
#     path            = data.terraform_remote_state.vault_setup.outputs.kubernetes_auth_path
#     role            = data.terraform_remote_state.vault_setup.outputs.vso_role_name
#     bound_namespaces = join(",", data.terraform_remote_state.vault_setup.outputs.vso_bound_namespaces)
#     audience        = data.terraform_remote_state.vault_setup.outputs.vso_audience
#     service_account = data.terraform_remote_state.vault_setup.outputs.vso_service_account
#   }

#   provisioner "local-exec" {
#     command = "echo '${local.auth_manifest}' | kubectl apply -f -"
#   }

#   provisioner "local-exec" {
#     when    = destroy
#     command = "kubectl delete certificate ${self.triggers.secret_name} -n ${self.triggers.namespace} --ignore-not-found=true"
#   }

#   depends_on = [null_resource.vso_connection]
# }