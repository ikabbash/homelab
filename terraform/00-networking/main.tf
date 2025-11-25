terraform {
  required_version = ">= 1.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

locals {
  cilium_l2_policy_manifest = templatefile("${path.module}/templates/cilium_l2_policy.yaml.tftpl", {
    namespace = "var.ingress_controller_chart_namespace"
  })
}

# Deploy Cilium
resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  namespace  = var.cilium_chart_namespace
  version    = var.cilium_chart_version
  skip_crds  = false

  values = [
    templatefile("./templates/cilium-values.yaml.tftpl", {
      api_host = var.cilium_service_host
    })
  ]
}

# Deploy F5's NGINX Ingress Controller
resource "helm_release" "ingress_controller" {
  name             = "nginx-ingress-controller"
  repository       = "https://helm.nginx.com/stable/"
  chart            = "nginx-ingress"
  namespace        = var.ingress_controller_chart_namespace
  version          = var.ingress_controller_chart_version
  skip_crds        = false
  create_namespace = true

  values = [
    templatefile("./templates/ingress-controller-values.yaml.tftpl", {
      loadbalancer_ip = var.ingress_controller_loadbalancer
    })
  ]
  depends_on = [helm_release.cilium]
}

resource "null_resource" "cilium_l2_policy" {
  triggers = {
    namespace        = var.ingress_controller_chart_namespace
    policy_name      = "nginx-ingress-l2-policy"
    manifest_content = local.cilium_l2_policy_manifest
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
    command = "kubectl delete ciliuml2announcementpolicy ${self.triggers.policy_name} -n ${self.triggers.namespace} --ignore-not-found=true"
  }

  depends_on = [helm_release.ingress_controller]
}