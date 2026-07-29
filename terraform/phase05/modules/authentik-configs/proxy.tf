resource "authentik_provider_proxy" "this" {
  for_each = var.proxy_apps

  name               = "${each.key}-proxy-provider"
  mode               = "proxy"
  authorization_flow = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow  = data.authentik_flow.default_invalidation_flow.id

  external_host = "https://${each.key}.${var.homelab_domain}"
  internal_host = each.value.internal_host
}

resource "authentik_application" "this" {
  for_each = var.proxy_apps

  name              = each.value.name
  slug              = each.key
  protocol_provider = authentik_provider_proxy.this[each.key].id
  meta_launch_url   = "https://${each.key}.${var.homelab_domain}"
  meta_icon         = each.value.meta_icon
}

resource "authentik_outpost_provider_attachment" "this" {
  for_each = var.proxy_apps

  outpost           = data.authentik_outpost.embedded.id
  protocol_provider = authentik_provider_proxy.this[each.key].id
}