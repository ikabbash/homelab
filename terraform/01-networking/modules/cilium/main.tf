locals {
  gateway_api_base = "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${var.gateway_api_version}/config/crd"
}

# Apply Gateway API CRDs
resource "terraform_data" "gateway_api_crds" {
  triggers_replace = {
    version = var.gateway_api_version
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -f ${local.gateway_api_base}/standard/gateway.networking.k8s.io_gatewayclasses.yaml
      kubectl apply -f ${local.gateway_api_base}/standard/gateway.networking.k8s.io_gateways.yaml
      kubectl apply -f ${local.gateway_api_base}/standard/gateway.networking.k8s.io_httproutes.yaml
      kubectl apply -f ${local.gateway_api_base}/standard/gateway.networking.k8s.io_referencegrants.yaml
      kubectl apply -f ${local.gateway_api_base}/standard/gateway.networking.k8s.io_grpcroutes.yaml
      kubectl apply -f ${local.gateway_api_base}/experimental/gateway.networking.k8s.io_tlsroutes.yaml
    EOT
  }
}

# Deploy Cilium
resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  namespace  = var.chart_namespace
  version    = var.chart_version
  skip_crds  = false

  values = [
    templatefile("${path.module}/templates/values.yaml.tftpl", {
      cluster_host = var.cluster_service_host
    })
  ]

  depends_on = [terraform_data.gateway_api_crds]
}