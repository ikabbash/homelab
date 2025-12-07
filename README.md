# Homelab
This repository contains a work-in-progress Kubernetes homelab setup with core infrastructure bootstrapped via Terraform and applications deployed using ArgoCD. Terraform provisions essential services like Cert Manager, Vault, and ArgoCD while ArgoCD manages the deployment of applications and ensures GitOps-driven infrastructure consistency.

<!-- ## Architecture -->

<!-- ## Hardware Overview -->

> ⚠️ Warning  
> The current Terraform setup is undergoing major refactoring, so this documentation may be outdated. For the last stable version, please refer to this [commit](https://github.com/ikabbash/homelab/tree/5f15149860d8bdcdec18e5c16dfadd01c0d1114f).

## What's Inside

<img src="docs/images/homelab-setup.png" alt="Homelab Secrets Diagram" width="800"/>

The setup is split into two main parts:
- Terraform (`terraform/`) which bootstraps the foundation in three stages (check the [doc](./terraform/README.md) for steps and explanation)
- ArgoCD which deploys and manages applications using manifests stored in this repo

This design keeps infrastructure changes tracked and versioned, making it straightforward to reproduce the cluster elsewhere if needed (for cases like creating a separate environment for testing, moving to new hardware, and so on). Terraform handles the bootstrapping of core services that ArgoCD depends on, while ArgoCD provides GitOps for everything else.

### Key Components
- Cert Manager: Handles TLS certificate management and automation using Let's Encrypt. Configured to use Cloudflare DNS challenges for domain validation
- Vault: Stores all secrets for the cluster. Acts as the single source of truth for sensitive data like API keys, database passwords, and service credentials
- Vault Secrets Operator (VSO): Syncs secrets from Vault into Kubernetes Secrets, letting pods use them natively without storing secrets in repos, improving security by keeping sensitive data out of source control
- ArgoCD: The GitOps engine that keeps the cluster in sync with this repository. Any changes pushed here get automatically reflected in the cluster

## Getting Started
Follow these steps to get the homelab up and running.

### Requirements
You'll need a few things prepared:
- [Cilium](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/) as the cluster's CNI (optional)
- F5's NGINX [Ingress Controller](https://docs.nginx.com/nginx-ingress-controller/installation/installing-nic/installation-with-helm/) (you can use the Helm values below)
  ```yaml
  controller:
    kind: daemonset
    enableCertManager: true
    enableCustomResources: true
    enableTLSPassthrough: true
    tlsPassThroughPort: 443
  ```
- A domain preferably managed through Cloudflare since that's what Cert Manager is configured to use for DNS challenges

Since this is a single-node private homelab without proper DNS (for now), you'll need to add entries to your `/etc/hosts` file to access services:

```
ip_address argocd.example.com vault.example.com etc.example.com
```

### Deployment
1. Work through the Terraform projects in order (`01-core-services` → `02-vault-setup` → `03-base-services`). Each directory has its own README with specific instructions
2. After Terraform completes, ArgoCD will be available and can start managing the applications

## Notes
- All storage currently resides on the local node using Kubernetes `hostPath`
- In case no one told you before, always back up your data before upgrading anything. For example, Vault does not make backward-compatibility guarantees for its data store so you better take backups

## To-do
What's planned for the homelab as it evolves. The ideas below may change and more may be added.

### Infra
- [x] Learn and setup Talos
- [ ] Setup [CloudNativePG](https://cloudnative-pg.io/)
- [ ] Deploy the following with ArgoCD
  - [ ] [homepage](https://github.com/gethomepage/homepage)
  - [ ] Scheduled backups
  - [ ] [n8n](https://docs.n8n.io/hosting/)
  - [ ] [FreshRSS](https://freshrss.org/)
  - [ ] [Karakeep](https://github.com/karakeep-app/karakeep)
  - [ ] [changedetection.io](https://github.com/dgtlmoon/changedetection.io/)
  - [ ] [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
  - [ ] [Grafana Loki](https://grafana.com/docs/loki/latest/setup/install/helm/)
  - [ ] [SonarQube](https://github.com/SonarSource/helm-chart-sonarqube)
- [ ] Monitoring and health checks
- [ ] DNS server
- [ ] Plan for a storage scalability (e.g. Longhorn, OpenEBS, Ceph, Synology, etc.)
- [x] Migrate from NGINX Ingress Controller to Cilium's Gateway API

### Security
- [ ] Deploy [Authentik](https://github.com/goauthentik/helm/blob/main/charts/authentik/README.md) using Terraform
  - [ ] Integrate SSO across platforms
  - [ ] Protect web apps with [M2M](https://youtu.be/bS_Pey6yAjA?si=fuhExwsYiVCINHAl)
- [ ] Setup audits (plan storage and retention accordingly)
  - [ ] Kubernetes audits
  - [ ] Vault audit logging 
  - [ ] Send logs to a central server
- [x] Define and enforce pod security contexts  
- [ ] Cilium network policies
  - [ ] Default deny all traffic between namespaces
- [ ] Scheduled jobs to scan containers for vulnerabilities

### n8n
- [ ] RSS feed summarizer
- [ ] Check every app installed by Helm for new versions and notify with a summary of the changelogs
  - [ ] Create PRs for automatic upgrade (e.g. update image tags in the manifests or chart version)
  - [ ] Notify on list of apps/repos releases (e.g. Kubernetes, GitLab)
- [ ] Alert for product verions approaching end of life
- [ ] Alert on newly discovered vulnerabilities for homelab apps