# The Authentik provider is declared in this module because it is a third-party
# (non-HashiCorp) provider and must be explicitly sourced and version-pinned
# to ensure consistent installs across environments.
terraform {
  required_version = ">= 1.0"

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "~> 2025"
    }
  }
}

provider "authentik" {
  url   = "https://${var.authentik_host}"
  token = var.authentik_api_token
}

data "authentik_flow" "default-provider-authorization-implicit-consent" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default-authorization-flow" {
  slug = "default-provider-authorization-explicit-consent"
}

data "authentik_flow" "default_invalidation_flow" {
  slug = "default-provider-invalidation-flow"
}

data "authentik_certificate_key_pair" "default" {
  name = "authentik Self-signed Certificate"
}

data "authentik_property_mapping_provider_scope" "scope_openid" {
  name = "authentik default OAuth Mapping: OpenID 'openid'"
}

data "authentik_property_mapping_provider_scope" "scope_email" {
  name = "authentik default OAuth Mapping: OpenID 'email'"
}

data "authentik_property_mapping_provider_scope" "scope_profile" {
  name = "authentik default OAuth Mapping: OpenID 'profile'"
}

resource "authentik_group" "homelab_admins" {
  name = "homelab-admins"
}

resource "authentik_group" "homelab_viewers" {
  name = "homelab-viewers"
}