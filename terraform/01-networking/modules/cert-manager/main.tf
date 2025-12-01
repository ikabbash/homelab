locals {
  clusterissuer_manifest = templatefile("${path.module}/templates/clusterissuer.yaml.tftpl", {
    cluster_issuer_name    = var.cluster_issuer_name
    letsencrypt_email      = var.letsencrypt_email
    cloudflare_secret_name = var.cloudflare_secret_name
  })
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = var.chart_namespace
  create_namespace = true
  version          = var.chart_version
  skip_crds        = false

  values = [
    templatefile("${path.module}/templates/values.yaml.tftpl", {
      namespace      = var.chart_namespace
    })
  ]
}

resource "kubernetes_secret_v1" "cloudflare_kubernetes_secret" {
  metadata {
    name      = var.cloudflare_secret_name
    namespace = var.chart_namespace
  }

  data = {
    api-token = var.cloudflare_api_token
  }

  depends_on = [helm_release.cert_manager]
}

resource "null_resource" "letsencrypt_cluster_issuer" {
  triggers = {
    cluster_issuer_name    = var.cluster_issuer_name
    letsencrypt_email      = var.letsencrypt_email
    cloudflare_secret_name = var.cloudflare_secret_name
    manifest_content       = local.clusterissuer_manifest
  }

  provisioner "local-exec" {
    command = "echo '${local.clusterissuer_manifest}' | kubectl apply -f -"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete clusterissuer ${self.triggers.cluster_issuer_name} --ignore-not-found=true"
  }

  depends_on = [
    helm_release.cert_manager,
    kubernetes_secret_v1.cloudflare_kubernetes_secret
  ]
}
