output "argocd_address" {
  description = "Complete domain name for ArgoCD"
  value       = module.argocd.argocd_address
}