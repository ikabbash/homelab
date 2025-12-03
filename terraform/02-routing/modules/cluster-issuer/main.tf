resource "kubernetes_secret_v1" "cloudflare_kubernetes_secret" {
  metadata {
    name      = var.cloudflare_secret_name
    namespace = var.cert_manager_namespace
  }

  data = {
    api-token = var.cloudflare_api_token
  }
}

resource "kubernetes_manifest" "cluster_issuer" {
  manifest = yamldecode(templatefile("${path.module}/templates/cluster-issuer.yaml.tftpl", {
    cluster_issuer_name    = var.cluster_issuer_name
    letsencrypt_email      = var.letsencrypt_email
    cloudflare_secret_name = var.cloudflare_secret_name
  }))

  depends_on = [kubernetes_secret_v1.cloudflare_kubernetes_secret]
}
