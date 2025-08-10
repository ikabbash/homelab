# ArgoCD Helm Values Overview

| Key / Path                                      | Description                                                                                          |
|-------------------------------------------------|------------------------------------------------------------------------------------------------------|
| `global.domain`                                 | Domain name for ArgoCD services; replace with your own.                                              |
| `server.certificate.enabled: true`              | Deploys a cert-manager `Certificate` resource to automatically create SSL certificates.              |
| `server.ingress.tls: true`                      | Enables TLS for the hostname (defaults to `global.domain`); requires the `argocd-server-tls` secret. |
| `server.ingress.annotations.cert-manager.io/cluster-issuer: "letsencrypt-prod"` | Uses the `letsencrypt-prod` ClusterIssuer via cert-manager for automatic TLS from Let’s Encrypt. |
| `server.insecure: true`                         | Runs ArgoCD API/UI without internal TLS since TLS is handled by an external ingress.                 |
| `dex.enabled: false`                            | Disables Dex authentication as this is a single-user, personal ArgoCD instance.                      |

**Note:** SSL-Passthrough configuration reference: [ArgoCD Helm Chart Docs](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd#ssl-passthrough)

ArgoCD's Helm Chart values: https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd