resource "random_password" "karakeep_client_id" {
  length  = 40
  special = false
}

resource "authentik_provider_oauth2" "karakeep" {
  name                       = "karakeep-oauth2-provider"
  client_id                  = random_password.karakeep_client_id.result
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
      url           = "https://karakeep.${var.homelab_domain}/api/auth/callback/custom"
    }
  ]

  depends_on = [random_password.karakeep_client_id]
}

resource "authentik_application" "karakeep" {
  name               = "Karakeep"
  slug               = "karakeep"
  protocol_provider  = authentik_provider_oauth2.karakeep.id
  open_in_new_tab    = true
  policy_engine_mode = "any"
  meta_icon          = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/karakeep.svg"

  depends_on = [authentik_provider_oauth2.karakeep]
}

resource "vault_kv_secret_v2" "karakeep_oauth" {
  mount = "homelab/infra/kv-secret"
  name  = "platforms/oauth/karakeep"

  data_json = jsonencode({
    client_id      = authentik_provider_oauth2.karakeep.client_id
    client_secret  = authentik_provider_oauth2.karakeep.client_secret
    well_known_url = "https://authentik.${var.homelab_domain}/application/o/${authentik_provider_oauth2.karakeep.name}/.well-known/openid-configuration"
  })

  depends_on = [authentik_provider_oauth2.karakeep]
}