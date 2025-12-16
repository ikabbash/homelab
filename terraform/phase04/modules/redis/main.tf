resource "kubernetes_persistent_volume_v1" "redis_pv" {
  metadata {
    name = "authentik-redis-pv"
  }
  spec {
    capacity = {
      storage = var.redis_storage_size
    }
    access_modes                     = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name               = "local-storage"
    persistent_volume_source {
      host_path {
        path = "${var.homelab_data_path}/authentik/redis"
        type = "DirectoryOrCreate"
      }
    }
    claim_ref {
      namespace = var.authentik_namespace
      name      = var.redis_pvc_name
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "redis_pvc" {
  metadata {
    name      = var.redis_pvc_name
    namespace = var.authentik_namespace
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "local-storage"
    resources {
      requests = {
        storage = var.redis_storage_size
      }
    }
  }

  depends_on = [kubernetes_persistent_volume_v1.redis_pv]
}

resource "kubernetes_service_v1" "redis_svc" {
  metadata {
    name      = "redis"
    namespace = var.authentik_namespace
  }
  spec {
    cluster_ip = "None"
    selector = {
      app = "redis"
    }
    port {
      name        = "redis"
      port        = 6379
      target_port = 6379
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_manifest" "redis_statefulset" {
  manifest = yamldecode(templatefile("${path.module}/templates/statefulset.yaml.tftpl", {
    namespace = var.authentik_namespace
    pvc_name  = kubernetes_persistent_volume_claim_v1.redis_pvc.metadata[0].name
  }))

  depends_on = [kubernetes_persistent_volume_claim_v1.redis_pvc]
}
