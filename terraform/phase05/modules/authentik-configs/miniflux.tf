resource "random_password" "miniflux_client_id" {
  length  = 40
  special = false
}

resource "authentik_provider_oauth2" "miniflux" {
  name                       = "miniflux-oauth2-provider"
  client_id                  = random_password.miniflux_client_id.result
  authorization_flow         = data.authentik_flow.default-authorization-flow.id
  invalidation_flow          = data.authentik_flow.default_invalidation_flow.id
  client_type                = "confidential"
  sub_mode                   = "hashed_user_id"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
  signing_key                = data.authentik_certificate_key_pair.default.id
  property_mappings = [
    data.authentik_property_mapping_provider_scope.scope_openid.id,
    data.authentik_property_mapping_provider_scope.scope_email.id,
    data.authentik_property_mapping_provider_scope.scope_profile.id,
  ]
  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = "https://miniflux.${var.homelab_domain}/oauth2/oidc/callback"
    }
  ]

  depends_on = [random_password.miniflux_client_id]
}

resource "authentik_application" "miniflux" {
  name               = "Miniflux"
  slug               = "miniflux"
  protocol_provider  = authentik_provider_oauth2.miniflux.id
  open_in_new_tab    = true
  policy_engine_mode = "any"
  meta_icon          = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/miniflux-light.svg"

  depends_on = [authentik_provider_oauth2.miniflux]
}

resource "vault_kv_secret_v2" "miniflux_oauth" {
  mount = "homelab/infra/kv-secret"
  name  = "platforms/oauth/miniflux"

  data_json = jsonencode({
    client_id          = authentik_provider_oauth2.miniflux.client_id
    client_secret      = authentik_provider_oauth2.miniflux.client_secret
    discovery_endpoint = "https://authentik.${var.homelab_domain}/application/o/${authentik_application.miniflux.slug}/"
    redirect_url       = "https://miniflux.${var.homelab_domain}/oauth2/oidc/callback"
  })

  depends_on = [authentik_provider_oauth2.miniflux]
}