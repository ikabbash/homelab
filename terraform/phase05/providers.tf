provider "helm" {
  kubernetes = {
    config_path = var.kubeconfig_path
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "vault" {
  address = "https://${data.terraform_remote_state.phase02.outputs.vault_host}"
}