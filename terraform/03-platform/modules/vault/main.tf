locals {
  certificate_manifest = templatefile("${path.module}/templates/certificate.yaml.tftpl", {
    namespace      = var.chart_namespace
    domain         = var.homelab_domain
    subdomain      = var.vault_subdomain
    cluster_issuer = var.cluster_issuer_name
    secret_name    = var.vault_secret_name
  })
}

resource "kubernetes_namespace" "vault_namespace" {
  metadata {
    name = var.chart_namespace
  }
}

resource "kubernetes_persistent_volume_v1" "vault_pv" {
  metadata {
    name = var.vault_pv_name
  }

  spec {
    capacity = {
      storage = var.vault_storage_size
    }
    access_modes                     = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Retain"
    persistent_volume_source {
      host_path {
        path = "${var.homelab_data_path}/vault"
        type = "DirectoryOrCreate"
      }
    }
    claim_ref {
      namespace = "vault"
      name      = var.vault_pvc_name
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "vault_pvc" {
  metadata {
    name      = var.vault_pvc_name
    namespace = var.chart_namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.vault_storage_size
      }
    }
    volume_name = kubernetes_persistent_volume_v1.vault_pv.metadata[0].name
  }
  depends_on = [kubernetes_namespace.vault_namespace]
}

# Certificate request for Vault TLS
resource "null_resource" "vault_certificate" {
  triggers = {
    namespace        = var.chart_namespace
    domain           = var.homelab_domain
    subdomain        = var.vault_subdomain
    cluster_issuer   = var.cluster_issuer_name
    secret_name      = var.vault_secret_name
    manifest_content = local.certificate_manifest
  }

  provisioner "local-exec" {
    command = "echo '${local.certificate_manifest}' | kubectl apply -f -"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete certificate ${self.triggers.secret_name} -n ${self.triggers.namespace} --ignore-not-found=true"
  }

  depends_on = [kubernetes_namespace.vault_namespace]
}

# F5's NGINX Ingress Controller for TLS Passthrough
resource "kubernetes_manifest" "vault_transport_server" {
  manifest = yamldecode(
    templatefile("${path.module}/templates/transportserver.yaml.tftpl", {
      namespace = var.chart_namespace
      domain    = var.homelab_domain
      subdomain = var.vault_subdomain
    })
  )

  depends_on = [kubernetes_namespace.vault_namespace]
}

resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  namespace  = var.chart_namespace
  version    = var.chart_version
  skip_crds  = false

  values = [
    templatefile("${path.module}/templates/values.yaml.tftpl", {
      namespace   = var.chart_namespace
      domain      = var.homelab_domain
      subdomain   = var.vault_subdomain
      secret_name = var.vault_secret_name
      pvc_name    = var.vault_pvc_name
    })
  ]

  depends_on = [
    kubernetes_persistent_volume_claim_v1.vault_pvc,
    null_resource.vault_certificate,
    kubernetes_manifest.vault_transport_server
  ]
}