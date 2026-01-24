resource "random_password" "postgres_password" {
  length  = 32
  special = false
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
    namespace             = var.authentik_namespace
    storage_class_name    = var.storage_class_name
    postgres_storage_size = var.postgres_storage_size
    secret_name           = kubernetes_secret.postgres_credentials.metadata[0].name
  }))
}
