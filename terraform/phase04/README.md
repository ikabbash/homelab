# Phase04: Authentik
This phase deploys Authentik with a PostgreSQL database. Authentik is used as the central identity provider for authentication and SSO across services within the cluster.

## Modules

### PostgreSQL
- Deploys PostgreSQL as a StatefulSet for Authentik data persistence.
- Database password is randomly generated.
- Dedicated for Authentik only.

### Authentik
- Deploys Authentik using Helm provider.
- Creates 2 persistent volume claims: One for media and the other for templates.
- Exposes Authentik through the Gateway using an `HTTPRoute`.
- Retrieves sensitive configuration (e.g. SMTP credentials) from Vault via VSO using `VaultStaticSecret`.
- Serves as the central SSO solution for services within the cluster.

## Steps
1. Initialize Terraform `terraform init`.
2. Deploy using `terraform apply`.
3. Complete the initial Authentik setup by creating an account at `https://your-authentik-host.com/if/flow/initial-setup/`.
    - You'll want to change the username after creating the account.

## Notes
- GeoIP is disabled.
- To confirm SMTP is configured correctly, you can run the following command:
    ```bash
    kubectl exec -it -n authentik deployment/authentik-worker -c worker -- ak test_email <your-email-address>
    ```
- Redis used to be part of Authentik's components but has been removed, you may check this [article](https://goauthentik.io/blog/2025-11-13-we-removed-redis/) to know why.
- Authentik application SSO configuration is handled in `phase05` and is separated because Authentik must first be initialized by creating an account and an admin API token.
- Tip: You can use [Gravatar](https://gravatar.com/) to link your email to a profile with a picture and basic info, so websites and apps can automatically display it.
    - Gravatar is a service that links your email to a profile with a picture and info, letting supported websites automatically display it.
- Authentik can expose Prometheus metrics (requires kube-prometheus-stack) to monitor background task processing, authentication and policy flows, request performance, and so on.

### Outputs
- `authentik_host` for `phase05` to authenticate with Authentik using API token.

### References
- Authentik configurations: https://docs.goauthentik.io/install-config/configuration/
- Authentik installation on Kubernetes: https://docs.goauthentik.io/install-config/install/kubernetes/
- Authentik PostgreSQL upgrade guide: https://docs.goauthentik.io/troubleshooting/postgres/upgrade_kubernetes/
- Authentik Helm values: https://artifacthub.io/packages/helm/goauthentik/authentik