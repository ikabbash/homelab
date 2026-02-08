output "argocd_host" {
  description = "Argo CD service hostname where Argo CD will be accessible"
  value       = module.argocd.argocd_host
}