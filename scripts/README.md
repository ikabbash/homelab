# Scripts

- `backup.sh`: Backs up all homelab app data (Authentik, Changedetection, Miniflux, n8n, Vault, Vaultwarden, etc.) to an encrypted restic repository, then pings healthchecks.io on success or failure.
  - Stages everything in a temp dir under `/tmp`, then runs an incremental, compressed, encrypted `restic backup`, prunes snapshots older than 7 days, and cleans up the staging dir on exit.
- `kubespray/k8s-setup.sh`: Bootstraps a bare-metal Kubernetes cluster on the given nodes using Kubespray and applies security hardening on top.
  - Clones Kubespray, configures the inventory, disables kube-proxy and nodelocaldns for a BYO-CNI setup (Cilium in our case), enables Pod Security Admission (restricted by default) and kubeadm cert auto-renewal, wires in a custom audit policy, then runs the Ansible playbook to install the cluster and validates the result.
- `vault-secrets/vault-secrets-init.sh`: Populates Vault with the homelab's KV secrets by sourcing a pre-filled config file (`vault-secrets.sh`).