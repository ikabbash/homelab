# Phase01: Cilium and Cert Manager
This phase deploys Cilium as the CNI with Gateway API enabled and L2 load balancer support, and Cert Manager with Gateway API integration. These are required to route traffic through a Gateway and handle TLS in later phases.

## Modules

### Cilium
- Deploys Cilium using the Helm provider.
- Replaces kube-proxy, enables Gateway API support and L2 announcements for LoadBalancer services.
    - Assuming you're using Talos Linux with kube-proxy not deployed.
- Also installs Gateway API CRDs required for Gateway and Route resources.
- Acts as the cluster networking layer and Gateway API implementation.

### Cert Manager
- Deploys Cert Manager using the Helm provider.
- Enables Gateway API support.
- Creates Kubernetes secret with Cloudflare API token for `ClusterIssuer` in `phase02`.
- Handles TLS certificate issuance and lifecycle management.

### OpenEBS
- Deploys OpenEBS using the Helm provider.
- Provides storage for the cluster using the LocalPV provisioner for node-local persistent volumes.
- Can be extended with Mayastor to support replicated and distributed storage across nodes.
- Acts as the primary storage layer for persisting volumes.

## Steps
1. Initialize Terraform `terraform init`.
2. Create `terraform.tfvars`:
    - Add control plane API IP or VIP into `cluster_service_host` variable.
    - Create Cloudflare API token following these [steps](https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/#api-tokens) and add it into `cloudflare_api_token` variable.
3. Deploy Helm charts using `terraform apply`.

## Notes
- Gateway API is enabled in Cilium, with Cert Manager configured to integrate with it for certificate management on Gateway resources created in later `phase02`.
- Gateway API CRDs are applied explicitly to control versioning via Terraform within Cilium module.
- `ClusterIssuer` is created in `phase02` because the Terraform Kubernetes provider can’t verify CRDs on first deployment.

### Outputs
- `cluster_issuer_secret_name` for `ClusterIssuer` resource in `phase02`.
- `host_storage_class_name` is used by any application that requires persistent volumes, such as Vault in `phase02` and Authentik (including its PostgreSQL database) in `phase04`.

### References
- Cert Manager Helm values: https://artifacthub.io/packages/helm/cert-manager/cert-manager
- Cert Manager Gateway API setup: https://cert-manager.io/docs/usage/gateway/
- Cert Manager Cloudflare's DNS challenge: https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/
- Cilium Gateway API setup with Cert Manager: https://blog.stonegarden.dev/articles/2023/12/cilium-gateway-api
- Cilium deployment on Talos Linux: https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium
- OpenEBS Helm values: https://github.com/openebs/openebs/blob/develop/charts/README.md