# Phase02: Gateway, Vault, and Vault Secrets Operator
This phase deploys Gateway resource, Vault, and Vault Secrets Operator (VSO). All traffic is routed through a single Gateway, with TLS certificates issued via Let’s Encrypt using Cert Manager. Vault is used for centralized secrets management to avoid storing secrets in the repository, and VSO syncs secrets from Vault into native Kubernetes secrets.

## Modules

### Gateway
- Creates a `ClusterIssuer` required for TLS secrets creation.
- Creates a single `Gateway` resource with 3 listeners.
    - HTTP listener for all namespaces (used mainly for HTTPS redirects via `HTTPRoute`).
    - HTTPS listener with a **wildcard** certificate for all namespaces.
    - TLS listener for Vault using TLS passthrough.
- Configures a Cilium L2 announcement policy (`CiliumL2AnnouncementPolicy`) to advertise the Gateway service external IP to be reachable.
- Defines a Cilium load balancer IP pool (`CiliumLoadBalancerIPPool`) that assigns and reserves the Gateway’s external IP for the Cilium Gateway service.
- Acts as the single entry point for all inbound traffic into the cluster.

### Vault
- Creates persistent volumes for Vault data storage.
- Creates a Cert Manager `Certificate` resource to issue the TLS secret.
    - The TLS secret is mounted into the Vault pod to enable end-to-end TLS.
- Creates an `HTTPRoute` to handle HTTP to HTTPS redirection.
- Creates a `TLSRoute` for Vault to enable TLS passthrough.
- Deploys Vault using Helm provider with a Raft storage backend and the UI enabled.
- Provides centralized secrets management with secure access through the Gateway.
    - Used primarily to store sensitive data such as API keys, passwords, and other credentials for applications.

### VSO
- Deploys VSO using Helm provider with `defaultVaultConnection` and `defaultAuthMethod` set to `false`.
    - `VaultAuthGlobal` and `VaultConnection` are created later in `phase03` because the providers cannot validate CRDs on first deployment.
- Syncs secrets from Vault into native Kubernetes secrets for application consumption.

## Steps
1. Initialize Terraform `terraform init`.
2. Create `terraform.tfvars`:
    - Set your homelab domain (e.g., homelab.example.com) in `homelab_domain`; all apps will use subdomains like argocd.homelab.example.com, vault.homelab.example.com, etc.
    - Set the Gateway external IP in `gateway_external_ip`; this is where services will be accessible.
    - Set your Let’s Encrypt email in `letsencrypt_email` for certificate registration.
3. Deploy using `terraform apply`.

## Notes
- Resources such as `Gateway`, `HTTPRoute`, and `ClusterIssuer` were not created in `phase01` due to the Terraform Kubernetes provider being unable to validate CRDs on first deployment. These are deployed here after Cert Manager and Cilium CRDs are available ([Github issue](https://github.com/hashicorp/terraform-provider-kubernetes/issues/2597)).
- `ClusterIssuer` created in `gateway` module depends on the `cluster_issuer_secret_name` output from `phase01`.
- HA is enabeld in Vault to be able to use Raft but replica is set to 1.
- For TLS secrets to be created, it may take approximately 90 seconds for the `challenges.acme.cert-manager.io` to be in a valid state and create the TLS secret.
- Requests to Vault using Vault's Kubernetes service domain (e.g. `vault.vault.svc.cluster.local`) is not supported due to TLS verification so you must use the exact domain specified in its assigned TLS certificate.

### Outputs
- `vault_address` for setup scripts and VSO's `VaultConnection` manifest in `phase03`.
- `vault_namespace` for setup scripts in `phase03`.
- `vso_namespace` for VSO to create `VaultConnection` and `VaultAuthGlobal` in `phase03`, and for `VaultAuth` creation in phase04 using `vaultAuthGlobalRef`.
- `gateway_name`, `gateway_namespace`, and `gateway_listener_https` for `HTTPRoute` resources in `phase04` and `phase05` for Authentik and Argo CD.
- `homelab_domain` for Argo CD and Authentik in `phase04` and `phase05` as the base domain (similar to Vault). Example subdomains: `argocd.homelab.example.com`, `vault.homelab.example.com`, etc.

### References
- Vault Helm values: https://github.com/hashicorp/vault-helm/blob/main/values.yaml
- Vault Secrets Operator Helm values: https://developer.hashicorp.com/vault/docs/deploy/kubernetes/vso/helm
- Gateway TLS Route for end-to-end TLS: https://gateway-api.sigs.k8s.io/guides/tls/
- Cilium L2 Announcement Policy: https://docs.cilium.io/en/latest/network/l2-announcements/
- Cilium LB IPAM: https://docs.cilium.io/en/stable/network/lb-ipam/