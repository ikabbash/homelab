# 02: Vault Setup
Sets up Vault using Terraform’s Vault provider to configure secret engines, auth methods, policies, and other core components. It also uses the Kubernetes provider to deploy the Vault Secrets Operator (VSO) `VaultConnection` and `VaultAuthGlobal`.

## Deployed Components
- KV v2 secrets engine at `homelab/infra/kv-secret` for infra (e.g. ArgoCD)
- KV v2 secrets engine at `homelab/apps/kv-secret` for apps
- Kubernetes auth method at `kubernetes/vso`
- Vault Policies (e.g. VSO read-only policy)
- VSO's `VaultConnection` and `VaultAuthGlobal` at its own namespace

### Secrets Tree
The diagram below shows a hierarchical organization of secrets, with infrastructure secrets divided into platform-specific and shared items (e.g., API keys, tokens) and application-specific secrets isolated per app. For example, infra-specific platforms like ArgoCD will have their secrets at the `homelab/infra/kv-secret` secrets engine (kv2).

<img src="../../docs/images/vault-secret-mounts.png" alt="Homelab Secrets Diagram" width="800"/>

Multiple KV secret mounts are implemented as a best practice to minimize the blast radius in case of a misconfiguration or compromise.

Note that the path of the secret engine (e.g., homelab infra's kv2) is `homelab/infra/kv-secret`, while the path of the stored keys (e.g., ArgoCD) is `platforms/argocd`.

### Kubernetes Auth Method
For the Kubernetes auth method (which is mainly for VSO), if Vault is running inside a Kubernetes pod you may omit the `token_reviewer_jwt` and `kubernetes_ca_cert`. Vault will automatically use the service-account token and CA certificate mounted at `/var/run/secrets/kubernetes.io/serviceaccount/`. In that case you can configure it like:

```bash
vault write auth/kubernetes/config \
    kubernetes_host=https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT
```

If Vault is running outside the cluster, you need to provide `token_reviewer_jwt` and `kubernetes_ca_cert` in its Kubernetes auth method configuration so Vault can validate JWTs and trust the Kubernetes API (check this [doc](https://developer.hashicorp.com/vault/docs/auth/kubernetes#configuration) for more).

```
vault write auth/kubernetes/config \
    token_reviewer_jwt="<your reviewer service account JWT>" \
    kubernetes_host=https://192.168.99.100:<your TCP port or blank for 443> \
    kubernetes_ca_cert=@ca.crt
```

The config in the Kubernetes auth method tells Vault how to communicate with the Kubernetes API and verify service account tokens.

The role defines which Kubernetes service accounts can authenticate and what Vault policies and permissions they receive once authenticated.

### VSO Auth Global
`vso-configs` module creates `VaultConnection` and `VaultAuthGlobal` Kubernetes resources allowing any namespace-specific VaultAuth to inherit configuration and authentication settings from VSO, ensuring consistent access across environments.

For example, when a new app is deployed in a new namespace, you only need to create a service account for the Kubernetes auth backend role and a `VaultAuth` resource in that namespace. This setup enables the app to obtain Kubernetes-native secrets via resources such as `VaultStaticSecret`.

```yaml
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultAuth
metadata:
  name: ${auth_name}
  namespace: ${namespace}
spec:
  kubernetes:
    role: ${role}
    serviceAccount: ${service_account}
  vaultAuthGlobalRef:
    allowDefault: true
    namespace: ${auth_global_namespace} # VSO's namespace
```

## Steps
1. After Vault has been successfully deployed and is running, you'll need to initialize it
    ```bash
    vault operator init --key-shares=5 --key-threshold=3 -format=json
    ```
    - You'll probably want to store the keys somewhere secure like a password manager. I use KeePassXC and created an entry for each key to unseal easily using `unseal.sh` script
        - If you set `key-shares` or `key-threshold` differently and use the `unseal.sh` script, you'll need to update the script accordingly
2. Setup AppRole auth method for Terraform by executing `setup.sh` script
    - You'll need to `vault login` with a token that has permissions to manage policies and configure AppRole authentication
    - You can use the root token for now, but it’s best to revoke it when you’re done
    - The script will automatically generate `terraform.tfvars` for you
3. Provision with Terraform:
    ```bash
    terraform init
    terraform plan
    terraform apply

    # Confirm
    vault secrets list
    vault auth list
    ```
4. Generate the ArgoCD password and server key, store them in Vault, and verify the entries 
    ```bash
    # Generate password for ArgoCD
    docker run --rm httpd:2.4-alpine htpasswd -bnBC 12 "" "your_password" | cut -d ':' -f2

    # Generate server key for ArgoCD
    openssl rand -base64 32

    # Put the keys into Vault
    vault kv put homelab/infra/kv-secret/platforms/argocd \
        admin.password='argocd_password' \
        server.secretkey='argocd_server_key'

    # Confirm
    vault kv get homelab/infra/kv-secret/platforms/argocd
    ```

## Notes
- Any secrets read or written via the Vault provider in Terraform are stored in Terraform’s state and plan files. It's recommended to not include secrets in your Terraform configuration or state wherever possible ([reference](https://registry.terraform.io/providers/hashicorp/vault/latest/docs))
- Terraform role's Secret ID lasts 4 hours, to create another one just re-execute `setup.sh`
- Terraform Vault provider's drift detection is a best-effort feature and shouldn't be relied on, as its accuracy depends on provider design and server-managed values. For example, if you add `max_lease_ttl_seconds` and later remove it from your Terraform configuration, Vault won't detect the drift, and the value will remain as it was last set
- It's best practice to revoke Vault's root token, you can regenerate it by following this [doc](https://developer.hashicorp.com/vault/docs/troubleshoot/generate-root-token) if needed
- Default `VaultAuthGlobal` resources are denoted by the name `default` and are automatically referenced by all `VaultAuth` resources when `spec.vaultAuthGlobalRef.allowDefault` is set to `true` and VSO is running with the `allow-default-globals` option set in the `-global-vault-auth-options` flag (the default). This is why when creating `VaultAuth` there is no need to specify the `VaultAuthGlobal` name because it uses the `default` one ([reference](https://developer.hashicorp.com/vault/docs/deploy/kubernetes/vso/sources/vault/auth#vaultauthglobal-configuration-inheritance))
- You may need to create additional auth methods if there are apps that directly use Vault’s API

### Terraform Outputs
- `infra_kv_mount_path` used for ArgocD's `VaultStaticSecret` which is in `03-base-services`
- `vso_role_name`, `kubernetes_auth_path`, and `vso_service_account` are all used for ArgoCD's `VaultAuth` to authenticate with Vault's Kubernetes auth method
- `vso_namespace` used for ArgoCD's `VaultAuth` for VSO's `VaultAuthGlobal`

### References
- VSO [authentication](https://developer.hashicorp.com/vault/docs/deploy/kubernetes/vso/sources/vault/auth)
- VSO [tutorial](https://developer.hashicorp.com/vault/tutorials/kubernetes-introduction/vault-secrets-operator)
- Terraform Vault [provider](https://registry.terraform.io/providers/hashicorp/vault/latest/docs)
- Terraform Kubernetes [provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)