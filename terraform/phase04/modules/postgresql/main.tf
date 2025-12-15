resource "random_password" "postgres_password" {
  length  = 32
  special = false
}

resource "kubernetes_persistent_volume_v1" "postgres_pv" {
  metadata {
    name = "authentik-postgres-pv"
  }
  spec {
    capacity = {
      storage = var.postgres_storage_size
    }
    access_modes                     = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name               = "local-storage"
    persistent_volume_source {
      host_path {
        path = "${var.homelab_data_path}/authentik/postgres"
        type = "DirectoryOrCreate"
      }
    }
    claim_ref {
      namespace = var.authentik_namespace
      name      = var.postgres_pvc_name
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "postgres_pvc" {
  metadata {
    name      = var.postgres_pvc_name
    namespace = var.authentik_namespace
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "local-storage"
    resources {
      requests = {
        storage = var.postgres_storage_size
      }
    }
  }

  depends_on = [kubernetes_persistent_volume_v1.postgres_pv]
}

resource "kubernetes_secret" "postgres_credentials" {
  metadata {
    name      = "authentik-postgres-credentials"
    namespace = var.authentik_namespace
  }
  data = {
    POSTGRES_PASSWORD = random_password.postgres_password.result
    POSTGRES_USER     = var.postgres_user
    POSTGRES_DB       = var.postgres_db
  }
}

resource "kubernetes_service_v1" "postgres_svc" {
  metadata {
    name      = "postgres"
    namespace = var.authentik_namespace
  }
  spec {
    cluster_ip = "None"
    selector = {
      app = "postgres"
    }
    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_manifest" "postgres_statefulset" {
  manifest = yamldecode(templatefile("${path.module}/templates/statefulset.yaml.tftpl", {
    secret_name = kubernetes_secret.postgres_credentials.metadata[0].name
    namespace   = var.authentik_namespace
    pvc_name    = kubernetes_persistent_volume_claim_v1.postgres_pvc.metadata[0].name
  }))

  depends_on = [kubernetes_persistent_volume_claim_v1.postgres_pvc]
}
