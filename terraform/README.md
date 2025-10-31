# Cluster Bootstrap
The Terraform directory contains three Terraform projects that must be applied in sequence to bootstrap the cluster's components:
- `01-core-services`: Deploys foundational components such as Cert Manager, Vault, and other core dependencies
- `02-vault-setup`: Configures Vault, including secret engines, authentication methods, and policies
- `03-base-services`: Installs ArgoCD and supporting services like Authentik

## Prerequisites
- Terraform 1.0+
- A valid kubeconfig for your cluster at `~/.kube/config`
- A domain registered and managed through Cloudflare (preferrably)

## Architecture

<img src="../docs/images/homelab-setup.png" alt="Homelab Secrets Diagram" width="800"/>

The design here is to provision Vault, Cert Manager and ArgoCD via Terraform because they form the foundational layer on which most things depend. For example, ArgoCD needs a valid TLS certificate from Cert Manager before it can function properly (which is like a chicken-and-egg situation), so it has to be installed first. Once that core stack is in place, ArgoCD takes over and manages all the other applications.

```
Cert Manager → Vault → Vault Secrets Operator → Vault Setup → ArgoCD
```

Cert Manager has to come first so it can issue the TLS certificate that Vault uses for secure communication. Once Vault is up, it’s configured with all the secret engines and auth methods it needs. Then the Vault Secrets Operator kicks in, pulling secrets from Vault—like ArgoCD’s admin password—and creating a `VaultStaticSecret` for ArgoCD's `argocd-secret` when ArgoCD starts. This order keeps everything wired up cleanly and makes sure secrets flow securely from the start.

Any new configs or updates for Vault are best handled in Terraform, since it keeps Vault’s setup consistent, versioned, and easy to reproduce across environments.