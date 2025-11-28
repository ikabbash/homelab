locals {
  cilium_l2_policy_manifest = templatefile("${path.module}/templates/l2policy.yaml.tftpl", {
    policy_name     = var.l2_policy_name
    chart_name      = helm_release.ingress_controller.name
    chart_namespace = var.chart_namespace
  })
}

# Deploy F5's NGINX Ingress Controller
resource "helm_release" "ingress_controller" {
  name             = "nginx-ingress"
  repository       = "https://helm.nginx.com/stable/"
  chart            = "nginx-ingress"
  namespace        = var.chart_namespace
  version          = var.chart_version
  skip_crds        = false
  create_namespace = true

  values = [
    templatefile("${path.module}/templates/values.yaml.tftpl", {
      loadbalancer_ip = var.lb_external_ip
    })
  ]
}

# L2 Announcement Policy
resource "null_resource" "cilium_l2_policy" {
  triggers = {
    policy_name      = var.l2_policy_name
    chart_name       = helm_release.ingress_controller.name
    chart_namespace  = var.chart_namespace
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

  depends_on = [helm_release.ingress_controller]
}