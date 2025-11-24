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
  name       = "nginx-ingress"
  repository = "oci://ghcr.io/nginx/charts/nginx-ingress"
  chart      = "nginx-ingress"
  namespace  = var.ingress_controller_chart_namespace
  version    = var.ingress_controller_chart_version
  skip_crds  = false

  values = [
    templatefile("./templates/ingress-controller-values.yaml.tftpl", {
      loadbalancer_ip = var.ingress_controller_loadbalancer
    })
  ]
  depends_on = [helm_release.cilium]
}