resource "authentik_provider_proxy" "bentopdf" {
  name               = "bentopdf-proxy-provider"
  mode               = "proxy"
  authorization_flow = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow  = data.authentik_flow.default_invalidation_flow.id

  external_host = "https://bentopdf.${var.homelab_domain}"
  internal_host = "http://bentopdf.bentopdf.svc"
}

resource "authentik_application" "bentopdf" {
  name              = "BentoPDF"
  slug              = "bentopdf"
  protocol_provider = authentik_provider_proxy.bentopdf.id
  meta_launch_url   = "https://bentopdf.${var.homelab_domain}"
  meta_icon         = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/bentopdf.svg"
}

resource "authentik_outpost_provider_attachment" "bentopdf" {
  outpost           = data.authentik_outpost.embedded.id
  protocol_provider = authentik_provider_proxy.bentopdf.id
}