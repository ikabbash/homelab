output "cluster_issuer_secret_name" {
  description = "Cloudflare API token Kubernetes secret name for DNS validation"
  value       = module.cert_manager.cluster_issuer_secret_name
}

output "host_storage_class_name" {
  description = "Name of the StorageClass created for OpenEBS hostpath volumes"
  value       = module.openebs.host_storage_class_name
}