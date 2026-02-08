output "authentik_host" {
  description = "Authentik service hostname where Authentik will be accessible"
  value       = "${var.authentik_subdomain}.${var.homelab_domain}"
}