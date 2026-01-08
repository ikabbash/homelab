resource "random_password" "argocd_client_id" {
  length  = 40
  special = false
}

resource "authentik_provider_oauth2" "argocd" {
  name                       = "argocd-oauth2-provider"
  client_id                  = random_password.argocd_client_id.result
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
      url           = "https://${var.argocd_address}/api/dex/callback"
    },
    {
      matching_mode = "strict"
      url           = "https://localhost:8085/auth/callback"
    }
  ]

  depends_on = [random_password.argocd_client_id]
}

resource "authentik_application" "argocd" {
  name               = "Argo CD"
  slug               = "argocd"
  protocol_provider  = authentik_provider_oauth2.argocd.id
  open_in_new_tab    = true
  policy_engine_mode = "any"
  meta_icon          = "https://raw.githubusercontent.com/cncf/artwork/main/projects/argo/icon/color/argo-icon-color.svg"

  depends_on = [authentik_provider_oauth2.argocd]
}