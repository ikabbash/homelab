locals {
  job_manifest = templatefile("${path.module}/templates/job.yaml.tftpl", {
    homelab_mount = var.homelab_mount
    namespace     = var.namespace
  })
}

resource "null_resource" "create_namespace" {
  triggers = {
    manifest_content = local.job_manifest
    namespace        = var.namespace
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl create ns ${var.namespace}
      kubectl label namespace ${var.namespace} pod-security.kubernetes.io/enforce=privileged --overwrite
    EOT
  }
}

resource "null_resource" "create_dirs" {
  triggers = {
    homelab_mount    = var.homelab_mount
    manifest_content = local.job_manifest
    namespace        = var.namespace
  }

  provisioner "local-exec" {
    command = <<EOF
kubectl apply -f - <<'EOF_MANIFEST'
${local.job_manifest}
EOF_MANIFEST
EOF
  }

  depends_on = [null_resource.create_namespace]
}

resource "null_resource" "delete_namespace" {
  triggers = {
    manifest_content = local.job_manifest
    namespace        = var.namespace
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Wait until the pod finishes
      while true; do
        phase=$(kubectl get pod -n ${var.namespace} -l job-name=dirs-init-job -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
        if [[ "$phase" == "Succeeded" ]] || [[ "$phase" == "Failed" ]]; then
          break
        fi
        sleep 5
      done

      # Get pod name and print logs
      POD_NAME=$(kubectl get pod -n ${var.namespace} -l job-name=dirs-init-job -o jsonpath='{.items[0].metadata.name}')
      echo "Created dirs:"
      kubectl logs -n ${var.namespace} $POD_NAME

      kubectl label namespace ${var.namespace} pod-security.kubernetes.io/enforce- || true
      kubectl delete ns ${var.namespace}
    EOT
  }

  depends_on = [null_resource.create_dirs]
}