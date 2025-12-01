# 03: Base Services
Deploys ArgoCD to the Kubernetes cluster using the official [Helm](https://registry.terraform.io/providers/hashicorp/helm/latest/docs) Terraform provider and deploys Vault Secrets Operator (VSO)'s `VaultStaticSecret` for ArgoCD's admin password and server key using the official [Kubernetes](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs) Terraform provider.

## Deployed Components
- ArgoCD
- `VaultStaticSecret` for `argocd-secret`

## Steps
Just apply the terraform and you're good to go
```bash
terraform init
terraform plan
terraform apply
```

## Notes
- `configs.secret.createSecret` is set to `false` in ArgoCD's Helm values so ArgoCD uses the admin password that's been put in Vault
    - To add secrets like `configs.secret.azureDevops.password` or `configs.secret.gitlabSecret`, add them to Vault and include them in the `argocd-secret` managed by VSO’s `VaultStaticSecret`
- TLS is terminated at the ingress controller for ArgoCD

### References
- ArgoCD [Helm Values](https://artifacthub.io/packages/helm/argo/argo-cd)
- Terraform Kubernetes [provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- Terraform Helm [provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)