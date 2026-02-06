# Phase05: Authentik Setup and Argo CD
This phase configures Authentik applications and providers (e.g. OIDC) for SSO and deploys Argo CD. Authentik is used as the identity provider, while Argo CD is deployed with SSO integration.

## Modules

### Authentik Configs
- Configures Authentik resources including providers, applications, and groups for each application’s SSO integration.
- Each application’s Authentik configuration is managed in a separate file within the module (e.g., Argo CD resources are defined in `argocd.tf`).
- Manages the creation of Authentik providers and applications for each service that will be integrated with SSO or other authentication flows.

### Argo CD
- Deploys Argo CD using Helm.
- Exposes Argo CD through the Gateway using an `HTTPRoute`.
- Integrates Argo CD with Authentik for SSO authentication.
- Prepares Argo CD for managing applications in the cluster.

## Steps
1. After creating an account in Authentik, create an API token:
    - Navigate to Admin interface ->  Directory -> Tokens and App passwords -> Create.
2. Copy your API token from Authentik and add it as the value for `authentik_api_token` in `terraform.tfvars`.
3. Initialize Terraform `terraform init`.
4. Deploy Authentik configuration and Argo CD using `terraform apply`.
5. Add your user to the `homelab-admins` group in Authentik:
    - Admin interface -> Directory -> Groups.
6. Visit Argo CD and congratulations, the Terraform part is done.

## Notes
- Argo CD does not create a default admin user, as this is disabled in the Helm chart.
- Additional providers and applications within Authentik can be managed to keep all SSO/auth flows infrastructure-as-code.  
    - For example, in the `authentik-configs` module, create `app_name.tf` to define `authentik_provider_oauth2`, `authentik_application`, and optionally `authentik_group` for the service you want to integrate.  
- The groups defined in Argo CD’s values file (like `homelab-admins` and `homelab-viewers`) correspond to the groups created in `authentik-configs` module, so users get the correct roles when logging in.
- The Authentik provider is declared inside this module because it is a third‑party (non‑HashiCorp) provider.
- Several data sources are used in the `authentik-configs` module to reference built‑in Authentik defaults (flows, scope/property mappings, certificate key pair), avoiding hard‑coding of IDs and ensuring Terraform correctly links to the necessary platform defaults. 
- Argo CD can expose Prometheus metrics to monitor application sync and health status, controller and API server activity, repo and commit server operations, and other performance signals.

### Outputs
- `argocd_address` shows the URL to access Argo CD.

### References
- Authentik SSO integration with Argo CD: https://integrations.goauthentik.io/infrastructure/argocd/
- Authentik Terraform OAuth2 provider resource: https://registry.terraform.io/providers/goauthentik/authentik/latest/docs/resources/provider_oauth2
- Authentik Terraform application resource: https://registry.terraform.io/providers/goauthentik/authentik/latest/docs/resources/application
- Authentik Terraform group resource: https://registry.terraform.io/providers/goauthentik/authentik/latest/docs/resources/group