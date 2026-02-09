resource "random_password" "grafana_client_id" {
  length  = 40
  special = false
}

resource "authentik_provider_oauth2" "grafana" {
  name                       = "grafana-oauth2-provider"
  client_id                  = random_password.grafana_client_id.result
  authorization_flow         = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow          = data.authentik_flow.default_invalidation_flow.id
  client_type                = "confidential"
  sub_mode                   = "hashed_user_id"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
  signing_key                = data.authentik_certificate_key_pair.default.id
  logout_method              = "frontchannel"
  property_mappings = [
    data.authentik_property_mapping_provider_scope.scope_openid.id,
    data.authentik_property_mapping_provider_scope.scope_email.id,
    data.authentik_property_mapping_provider_scope.scope_profile.id,
  ]
  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = "https://grafana.${var.homelab_domain}/login/generic_oauth"
    },
    {
      matching_mode = "strict"
      url           = "https://grafana.${var.homelab_domain}/logout"
    }
  ]

  depends_on = [random_password.grafana_client_id]
}

resource "authentik_application" "grafana" {
  name               = "Grafana"
  slug               = "grafana"
  protocol_provider  = authentik_provider_oauth2.grafana.id
  open_in_new_tab    = true
  policy_engine_mode = "any"
  meta_icon          = "https://upload.wikimedia.org/wikipedia/commons/3/3b/Grafana_icon.svg"

  depends_on = [authentik_provider_oauth2.grafana]
}

resource "vault_kv_secret_v2" "grafana_oauth" {
  mount = "homelab/infra/kv-secret"
  name  = "platforms/oauth/grafana"

  data_json = jsonencode({
    client_id     = authentik_provider_oauth2.grafana.client_id
    client_secret = authentik_provider_oauth2.grafana.client_secret
  })

  depends_on = [authentik_provider_oauth2.grafana]
}