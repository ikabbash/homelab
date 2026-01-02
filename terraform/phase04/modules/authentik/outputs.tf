output "authentik_address" {
  description = "Complete domain name for Authentik"
  value       = "${var.authentik_subdomain}.${var.homelab_domain}"
}