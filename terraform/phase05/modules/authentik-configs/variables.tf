# Required
variable "homelab_domain" {
  description = "Domain name for the homelab environment"
  type        = string
}

# Required
variable "argocd_host" {
  description = "Argo CD service hostname where Argo CD will be accessible"
  type        = string
}

# Required
variable "authentik_host" {
  description = "Authentik service hostname where Authentik will be accessible"
  type        = string
}

# Required
variable "authentik_api_token" {
  description = "Authentik admin API token for Terraform"
  type        = string
}

variable "proxy_apps" {
  type = map(object({
    name          = string
    internal_host = string
    meta_icon     = string
  }))
  default = {
    bentopdf = {
      name          = "BentoPDF"
      internal_host = "http://bentopdf.bentopdf.svc"
      meta_icon     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/bentopdf.svg"
    }
    alloy = {
      name          = "Alloy"
      internal_host = "http://alloy.monitoring.svc:12345"
      meta_icon     = "https://cdn.jsdelivr.net/gh/selfhst/icons/svg/grafana-alloy.svg"
    }
  }
}