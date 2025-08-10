# Cert-Manager Setup

TLS in this cluster is managed by **cert-manager**. When an Ingress resource is created, cert-manager automatically issues a TLS certificate using Cloudflare's DNS challenge via the Cloudflare API token.

This setup is designed for Cloudflare using the **DNS-01 challenge**.

Follow the official [cert-manager Cloudflare DNS01 guide](https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/) to generate a Cloudflare API token. Store it as a Kubernetes secret:
```bash
kubectl -n cert-manager create secret generic cloudflare-api-token-secret \
  --from-literal=api-token='<YOUR_API_TOKEN>'
```

Create a `ClusterIssuer` resource similar to [`cluster-issuer.yaml`](../manifests/cert-manager/cluster-issuer.yaml) (will be automated in the future after Vault is implemented). Update the email address before applying.
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: you@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
      - dns01:
          cloudflare:
            apiTokenSecretRef:
              name: cloudflare-api-token-secret
              key: api-token
```

## Troubleshooting & References
Check cert-manager resources in case the TLS secret wasn't created:
```bash
kubectl get certificate -A
kubectl get order,challenge -A
```

- [Cert-Manager Helm Chart](https://cert-manager.io/docs/installation/helm/)  
- [Cert-Manager Helm Values Reference](https://artifacthub.io/packages/helm/cert-manager/cert-manager)