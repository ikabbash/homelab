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
  cilium_l2_policy_manifest = templatefile("${path.module}/templates/cilium-lb-l2-policy.yaml.tftpl", {
    policy_name  = var.cilium_l2_policy_name
    gateway_name = var.gateway_name
  })

  ip_pool_name = "${var.gateway_name}-ip-pool"
  cilium_gateway_manifest = templatefile("${path.module}/templates/cilium-gateway.yaml.tftpl", {
    gateway_name    = var.gateway_name
    loadbalancer_ip = var.lb_service_external_ip
    ip_pool_name    = local.ip_pool_name
  })

  gateway_api_base = "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${var.gateway_api_version}/config/crd"
}

# Apply Gateway API CRDs
resource "null_resource" "gateway_api_crds" {
  triggers = {
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
  namespace  = var.cilium_chart_namespace
  version    = var.cilium_chart_version
  skip_crds  = false

  values = [
    templatefile("./templates/cilium-values.yaml.tftpl", {
      api_host = var.cilium_service_host
    })
  ]

  depends_on = [null_resource.gateway_api_crds]
}

# Deploy F5's NGINX Ingress Controller
# resource "helm_release" "ingress_controller" {
#   name             = "nginx-ingress"
#   repository       = "https://helm.nginx.com/stable/"
#   chart            = "nginx-ingress"
#   namespace        = var.ingress_controller_chart_namespace
#   version          = var.ingress_controller_chart_version
#   skip_crds        = false
#   create_namespace = true

#   values = [
#     templatefile("./templates/ingress-controller-values.yaml.tftpl", {
#       loadbalancer_ip = var.lb_service_external_ip
#     })
#   ]
#   depends_on = [helm_release.cilium]
# }

resource "null_resource" "cilium_l2_policy" {
  triggers = {
    policy_name      = var.cilium_l2_policy_name
    gateway_name     = var.gateway_name
    ip_pool_name     = local.ip_pool_name
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
    command = "kubectl delete ciliuml2announcementpolicy ${self.triggers.policy_name} --ignore-not-found=true"
  }
}

resource "null_resource" "cilium_gateway" {
  triggers = {
    gateway_name     = var.gateway_name
    ip_pool_name     = local.ip_pool_name
    loadbalancer_ip  = var.lb_service_external_ip
    manifest_content = local.cilium_gateway_manifest
  }

  provisioner "local-exec" {
    command = <<-EOT
      cat <<EOF | kubectl apply -f -
      ${local.cilium_gateway_manifest}
      EOF
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl delete gateway ${self.triggers.gateway_name} --ignore-not-found=true
      kubectl delete ciliumloadbalancerippool ${self.triggers.ip_pool_name} --ignore-not-found=true
    EOT
  }
}