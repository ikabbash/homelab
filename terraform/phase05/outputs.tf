output "argocd_address" {
  description = "Complete domain name for Argo CD"
  value       = module.argocd.argocd_address
}