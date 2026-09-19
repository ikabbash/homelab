# Authentik
Identity provider for the homelab, handling SSO for internal apps. Config lives in Terraform (phase05's `authentik-configs` module).

Apps integrate one of two ways depending on whether they have OIDC natively.

## Native OIDC apps
Apps like Argo CD and Grafana support OIDC, so each gets its own `authentik_provider_oauth2` + `authentik_application`. Client ID is a random string, client secret is Authentik-generated and pushed straight to Vault (`vault_kv_secret_v2`) rather than committed anywhere so a Kubernetes-native secret is created for the app through Vault Secrets Operator.

## Proxy apps (no native SSO)
Apps with no OIDC support (BentoPDF, Prometheus, Glance, etc.) sit behind Authentik's **Embedded Outpost** instead. Each gets an `authentik_provider_proxy` mapping a public `external_host` to its in-cluster `internal_host`, and an `authentik_outpost_provider_attachment` wiring that provider into the outpost. The outpost then reverse-proxies the app: it checks the session on every request and forwards through to `internal_host` once authenticated.

### Adding a new proxied UI page
1. Add the app to `proxy_apps` (`name`, `internal_host`, `meta_icon`) in Terraform phase05's `authentik-configs` module, this creates its provider, application, and outpost attachment.
2. Add an entry to phase04's `egress_services` variable (Authentik deployment module) to update Authentik's network policy so Authentik is allowed to reach the app's Service:
  ```hcl
  { name = "bentopdf", namespace = "bentopdf", port = "8080" }
  ```
3. On the app's own network policy, allow ingress from Authentik:
  ```yaml
  ingress:
    - fromEndpoints:
        - matchLabels:
            io.kubernetes.pod.namespace: authentik
            app.kubernetes.io/instance: authentik
  ```
4. Point the app's HTTPRoute at Authentik's service instead of its own, so traffic hits the outpost first:
  ```yaml
  backendRefs:
    - name: authentik-server
      namespace: authentik
      port: 80
  ```