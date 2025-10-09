resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = var.chart_namespace
  create_namespace = true
  version          = var.chart_version
  skip_crds        = true

  values = [
    templatefile("${path.module}/templates/values.yaml.tftpl", {
      namespace = var.chart_namespace
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
    manifest_content = templatefile("${path.module}/templates/clusterissuer.yaml.tftpl", {
      cluster_issuer_name    = var.cluster_issuer_name
      letsencrypt_email      = var.letsencrypt_email
      cloudflare_secret_name = var.cloudflare_secret_name
    })
  }

  provisioner "local-exec" {
    command = <<-EOT
      cat <<EOF | kubectl apply -f -
      ${templatefile("${path.module}/templates/clusterissuer.yaml.tftpl", {
    cluster_issuer_name    = var.cluster_issuer_name
    letsencrypt_email      = var.letsencrypt_email
    cloudflare_secret_name = var.cloudflare_secret_name
})}
      EOF
    EOT
}

provisioner "local-exec" {
  when    = destroy
  command = "kubectl delete clusterissuer letsencrypt-prod --ignore-not-found=true"
}

depends_on = [
  helm_release.cert_manager,
  kubernetes_secret_v1.cloudflare_kubernetes_secret
]
}