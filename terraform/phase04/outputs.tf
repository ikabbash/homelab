output "authentik_host" {
  description = "Authentik service hostname where Authentik will be accessible"
  value       = module.authentik.authentik_host
}