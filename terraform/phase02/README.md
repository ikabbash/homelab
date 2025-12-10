# 01: Core Services
Deploys Cert Manager, Vault, and Vault Secrets Operator (VSO) to the Kubernetes cluster. Uses the official [Kubernetes](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs), [Helm](https://registry.terraform.io/providers/hashicorp/helm/latest/docs), and [null resource](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) Terraform providers.

TLS certificates are issued via Let’s Encrypt using cert-manager with a DNS-01 challenge handled through Cloudflare.

In case you don't want to use DNS challenge with Cloudflare, you'll need to choose a different [method](https://cert-manager.io/docs/configuration/acme/) and modify the Cert Manager Terraform module accordingly.

## Deployed Components
- Cert Manager
    - Kubernetes Secret with Cloudflare's API token
    - Cluster Issuer
- Vault
    - PV and PVC
    - Certificate for TLS secret creation
    - F5 NGINX Ingress Controller's `TransportServer` for TLS passthrough
- Vault Secrets Operator

## Steps
1. If you'll use DNS challenge with Cloudflare, follow Cert Manager's [steps](https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/) on creating an API token
2. Create `terraform.tfvars` file and add your values
3. Provision with terraform:
    ```bash
    terraform init
    terraform plan
    terraform apply
    ```

## Notes
- The `null_resource` is used for `letsencrypt_cluster_issuer` and `vault_certificate` as a workaround because using the Kubernetes provider directly causes Terraform to fail when verifying the manifests. During `terraform plan`, it checks for the CRDs before they’re installed (which only happens after the Helm release), so it can’t recognize those resources yet and the validation fails
    - The creation of Vault Secrets Operator's `defaultVaultConnection` and `defaultAuthMethod` are also disabled for that same reason
    - Check this Github [issue](https://github.com/hashicorp/terraform-provider-kubernetes/issues/2597)
- Vault is configured to use Raft as a backend storage on a volume as it's simpler compared to other backends
    - HA is enabeld in Vault to use Raft but replica is set to 1
- After Vault's certificate has been created by Cert Manager, the TLS secret is mounted inside Vault to enable end-to-end TLS
    - `TransportServer` is the replacement of ingress for Vault to enable TLS passthrough
    - Make sure Transport Server is enabled in F5's Ingress Controller (look for `controller.enableTLSPassthrough` in the [docs](https://docs.nginx.com/nginx-ingress-controller/installation/installing-nic/installation-with-helm/))
    - If you use a different ingress controller you'll probably need to modify the module
- For TLS secret to be created, it may take approximately 90s for the `challenges.acme.cert-manager.io` to be in a valid state and create the TLS secret
    - You may need to restart the Vault container if it’s stuck at `ContainerCreating` because it depends on the TLS secret created by cert-manager’s DNS challenge
- Requests to Vault using Vault's Kubernetes service domain (e.g. `vault.vault.svc.cluster.local`) is not supported due to TLS verification so you must use the exact domain specified in its assigned TLS certificate

### Terraform Outputs
- `cluster_issuer_name` used in `03-base-services` for ArgocD's ingress to create a certificate
- `vault_address` used in `02-vault-setup` for both Vault's setup script and Vault Secrets Operator's connection manifest
- `vault_namespace` used in `02-vault-setup` for Vault's setup script
- `vso_namespace` used in `02-vault-setup` for Vault Secrets Operator creating `VaultConnection` and `VaultAuthGlobal` in the same namespace
- `homelab_domain` used in `03-base-services` for ArgoCD to use as base domain (similar to Vault)

### References
- Cert Manager Cloudflare's [DNS challenge](https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/)
- Cert Manager [Helm values](https://artifacthub.io/packages/helm/cert-manager/cert-manager)
- Vault [Helm values](https://github.com/hashicorp/vault-helm/blob/main/values.yaml)
- Vault Secrets Operator [Helm values](https://developer.hashicorp.com/vault/docs/deploy/kubernetes/vso/helm)
- Terraform Kubernetes [provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- Terraform Helm [provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)