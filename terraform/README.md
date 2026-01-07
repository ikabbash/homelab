# Terraform
Terraform is used to provision and manage the cluster’s foundational platform components, such as Cilium, Vault, Cert Manager, Authentik, and ArgoCD. These services form a base layer that other workloads depend on. These services are intentionally managed outside of ArgoCD to avoid dependency ordering issues and manual setup steps.

Some components introduce circular dependencies when managed purely through GitOps. For example, ArgoCD benefits from having SSO available immediately, which depends on Authentik. Authentik, in turn, requires secrets sourced from Vault. Managing these components through Terraform allows the entire foundation to be provisioned deterministically and with minimal manual intervention.

## Platform Provisioning
<img src="../docs/images/homelab-setup.png" alt="Homelab Secrets Diagram" width="800"/>

This architecture cleanly separates responsibilities between Terraform and ArgoCD. Terraform provisions and maintains the core services that other workloads rely on, while ArgoCD handles continuous deployment of applications.

Vault and Authentik configurations are intentionally managed through Terraform to keep their setup consistent and versioned. This approach also makes it straightforward to recreate the cluster in another environment, such as for testing or migrating to new hardware.

### Terraform Phases
Components are provisioned through five Terraform projects (phases), which must be executed in order:
- `phase01`: Deploys Cilium as the CNI with Gateway API enabled and deploys Cert Manager.
- `phase02`: Creates a single Gateway and deploys Vault along with the Vault Secrets Operator (VSO).
- `phase03`: Manages Vault configuration as code and creates VSO connection resources for global authentication.
- `phase04`: Deploys PostgreSQL and Authentik as the central identity provider and SSO solution.
- `phase05`: Manages Authentik configuration as code, sets up applications and providers for SSO integration, and deploys ArgoCD with SSO enabled.

### Prerequisites
- Terraform 1.0+.
- A valid kubeconfig for your cluster at `~/.kube/config`.
- A domain registered and managed through Cloudflare.
  - For Cert Manager's DNS challenge.

### Notes
- This setup currently targets a single-node cluster and uses `hostPath` volumes for persistent storage.
- Required directories and permissions must be created manually before deploying workloads that rely on persistent volumes.
- The following script creates the necessary directories and sets proper ownership for each application. You may execute it after `phase01` is done:
  ```bash
  kubectl label namespace default pod-security.kubernetes.io/enforce=privileged --overwrite

  kubectl apply -f - <<'EOF'
  apiVersion: v1
  kind: Pod
  metadata:
    name: dirs-creator
  spec:
    restartPolicy: Never
    containers:
    - name: dirs-creator
      image: alpine
      command:
        - sh
        - -c
        - |
          mkdir /var/mnt/homelab/vault
          chown 100:1000 /var/mnt/homelab/vault
          mkdir -p /var/mnt/homelab/authentik/postgres
          mkdir -p /var/mnt/homelab/authentik/media
          mkdir -p /var/mnt/homelab/authentik/templates
          chown -R 1000:1000 /var/mnt/homelab/authentik
          ls -l /var/mnt/homelab
      volumeMounts:
        - name: homelab
          mountPath: /var/mnt/homelab
    volumes:
      - name: homelab
        hostPath:
          path: /var/mnt/homelab
          type: Directory
  EOF

  kubectl wait --for=condition=Completed pod/dirs-creator --timeout=10s

  kubectl logs dirs-creator

  kubectl delete pod dirs-creator

  kubectl label namespace default pod-security.kubernetes.io/enforce- --overwrite
  ```

### Providers Used
- HashiCorp Kubernetes [provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs).
- HashiCorp Helm [provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs).
- HashiCorp Vault [provider](https://registry.terraform.io/providers/hashicorp/vault/latest/docs).
- Authentik (goauthentik) [provider](https://registry.terraform.io/providers/goauthentik/authentik/latest/docs).