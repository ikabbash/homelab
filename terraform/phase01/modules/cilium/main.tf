locals {
  gateway_api_repo              = "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api"
  gateway_api_base              = "${local.gateway_api_repo}/${var.gateway_api_version}/config/crd/standard"
  gateway_api_experimental_base = "${local.gateway_api_repo}/${var.gateway_api_version}/config/crd/experimental"
}

# Apply Gateway API CRDs
resource "terraform_data" "gateway_api_crds" {
  triggers_replace = {
    version           = var.gateway_api_version
    base              = local.gateway_api_base
    experimental_base = local.gateway_api_experimental_base
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      kubectl apply -f ${local.gateway_api_base}/gateway.networking.k8s.io_gatewayclasses.yaml
      kubectl apply -f ${local.gateway_api_base}/gateway.networking.k8s.io_gateways.yaml
      kubectl apply -f ${local.gateway_api_base}/gateway.networking.k8s.io_httproutes.yaml
      kubectl apply -f ${local.gateway_api_base}/gateway.networking.k8s.io_referencegrants.yaml
      kubectl apply -f ${local.gateway_api_base}/gateway.networking.k8s.io_grpcroutes.yaml
      kubectl apply -f ${local.gateway_api_base}/gateway.networking.k8s.io_backendtlspolicies.yaml
      kubectl apply -f ${local.gateway_api_experimental_base}/gateway.networking.k8s.io_tlsroutes.yaml
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
      cluster_host      = var.cluster_service_host
      enable_monitoring = var.enable_monitoring
    })
  ]

  depends_on = [terraform_data.gateway_api_crds]
}