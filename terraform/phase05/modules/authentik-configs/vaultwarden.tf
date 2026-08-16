resource "authentik_property_mapping_provider_scope" "vaultwarden_email" {
  name       = "Vaultwarden Email Scope"
  scope_name = "email"
  expression = <<-EOT
    return {
        "email": request.user.email,
        "email_verified": True,
    }
  EOT
}

resource "random_password" "vaultwarden_client_id" {
  length  = 40
  special = false
}

resource "authentik_provider_oauth2" "vaultwarden" {
  name                        = "vaultwarden-oauth2-provider"
  client_id                   = random_password.vaultwarden_client_id.result
  authorization_flow          = data.authentik_flow.default-authorization-flow.id
  invalidation_flow           = data.authentik_flow.default_invalidation_flow.id
  client_type                 = "confidential"
  sub_mode                    = "hashed_user_id"
  include_claims_in_id_token  = true
  issuer_mode                 = "per_provider"
  grant_types                 = ["authorization_code", "refresh_token"]
  signing_key                 = data.authentik_certificate_key_pair.default.id
  access_token_validity       = "minutes=30"

  property_mappings = [
    data.authentik_property_mapping_provider_scope.scope_openid.id,
    authentik_property_mapping_provider_scope.vaultwarden_email.id,
    data.authentik_property_mapping_provider_scope.scope_profile.id,
    data.authentik_property_mapping_provider_scope.scope_offline_access.id,
  ]

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      url               = "https://vaultwarden.${var.homelab_domain}/identity/connect/oidc-signin"
      redirect_uri_type = "authorization"
    }
  ]

  depends_on = [random_password.vaultwarden_client_id, authentik_property_mapping_provider_scope.vaultwarden_email]
}

resource "authentik_application" "vaultwarden" {
  name               = "Vaultwarden"
  slug               = "vaultwarden"
  protocol_provider  = authentik_provider_oauth2.vaultwarden.id
  open_in_new_tab    = true
  policy_engine_mode = "any"
  meta_icon          = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/vaultwarden-light.svg"

  depends_on = [authentik_provider_oauth2.vaultwarden]
}

resource "vault_kv_secret_v2" "vaultwarden_oauth" {
  mount = "homelab/infra/kv-secret"
  name  = "platforms/oauth/vaultwarden"

  data_json = jsonencode({
    client_id          = authentik_provider_oauth2.vaultwarden.client_id
    client_secret      = authentik_provider_oauth2.vaultwarden.client_secret
    discovery_endpoint = "https://authentik.${var.homelab_domain}/application/o/${authentik_application.vaultwarden.slug}/"
  })

  depends_on = [authentik_provider_oauth2.vaultwarden]
}