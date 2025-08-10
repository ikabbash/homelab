# Overview
This repository contains my homelab infrastructure configuration, managed primarily with ArgoCD, and is a work in progress as I explore, refine, and address pending improvements.

## ArgoCD
ArgoCD is initially deployed manually using the app-of-apps pattern, with configuration from [`manifests/argocd/values.yaml`](./manifests/argocd/values.yaml). To begin, install ArgoCD:
```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# For Debian based distros
sudo apt update
sudo apt install apache2-utils
htpasswd -nbBC 10 "" "YourPasswordHere" | tr -d ':\n' | sed 's/$2y/$2a/'

helm upgrade -i argocd argo/argo-cd -n argocd \
    --create-namespace \
    -f values.yaml \
    --set configs.secret.argocdServerAdminPassword="Bcrypt hashed password" \
    --version 8.0.0
```

When creating new cluster, you'll need to manually add `super-app.yaml` into ArgoCD so everything else will be installed.

### Components
| Component      | Purpose                                                   |
|----------------|-----------------------------------------------------------|
| controller     | Reconciles desired Git state with live cluster state.     |
| repoServer     | Fetches and renders manifests from Git, Helm, Kustomize.  |
| dex            | Provides OAuth/OIDC-based user authentication.            |
| redis          | Speeds up operations with cached and ephemeral data.      |
| notifications  | Sends alerts triggered by app events or sync changes.     |
| server         | Hosts API/UI, manages RBAC, and coordinates user actions. |

# To-do
- [ ] Integrate Vault for secret management  
  - [ ] Automate creation of currently manual resources (e.g., cert-manager secret and cluster issuer)  
- [ ] Apply DevSecOps best practices across the setup  
  - [ ] Define and enforce pod security contexts  
- [ ] Refactor documentation for clarity and structure  
- [ ] Configure ArgoCD to send alerts via email and Slack