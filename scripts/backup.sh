#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Homelab backup script
# Usage: ./homelab-backup.sh /path/to/backup https://hc-ping.com/your-uuid-here
#   -> stages everything in a temp dir under /tmp (encrypted-only at rest)
#   -> restic repo lives at /mnt/archive/homelab-restic-repo
# ---------------------------------------------------------------------------

DEST_ROOT="${1:?Usage: $0 <backup-destination-dir> <healthchecks-ping-url>}"
HC_PING_URL="${2:?Usage: $0 <backup-destination-dir> <healthchecks-ping-url>}"
RESTIC_REPO="$DEST_ROOT/homelab-restic-repo"
RESTIC_PASSWORD_FILE="$HOME/.restic-password" # chmod 600 this file

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') ==> $*"; }

on_exit() {
  local exit_code=$?
  rm -rf "$DEST" 2>/dev/null || true
  if [ "$exit_code" -ne 0 ]; then
    log "ERROR: script exited with code $exit_code"
    curl -fsS -m 10 --retry 2 "${HC_PING_URL}/fail" >/dev/null 2>&1 || true
  else
    curl -fsS -m 10 --retry 2 "${HC_PING_URL}" >/dev/null 2>&1 || true
  fi
}
trap on_exit EXIT

log "Checking cluster reachability"
if ! kubectl get --raw='/healthz' --request-timeout=10s >/dev/null 2>&1; then
  log "ERROR: cluster is not reachable, aborting backup"
  exit 1
fi

umask 077   # anything created from here on defaults to owner-only permissions

DEST=$(mktemp -d /tmp/homelab-backup-staging.XXXXXX)

APPS=(authentik changedetection miniflux n8n vault vaultwarden trivy-operator)
for app in "${APPS[@]}"; do
  mkdir -p "$DEST/$app"
done

# Helper: resolve the current pod name for a Deployment (kubectl cp needs a pod name)
pod_for_deployment() {
  local ns="$1" dep="$2" selector
  selector=$(kubectl get deployment "$dep" -n "$ns" \
    -o go-template='{{range $k,$v := .spec.selector.matchLabels}}{{$k}}={{$v}},{{end}}' \
    | sed 's/,$//')
  kubectl get pods -n "$ns" -l "$selector" -o jsonpath='{.items[0].metadata.name}'
}

# Postgres dumps: authentik, miniflux, n8n (all StatefulSet pod postgres-0)
POSTGRES_NAMESPACES=(authentik miniflux n8n)
for ns in "${POSTGRES_NAMESPACES[@]}"; do
  log "[$ns] dumping postgres"
  user=$(kubectl exec -n "$ns" postgres-0 -- printenv POSTGRES_USER)
  kubectl exec -n "$ns" postgres-0 -- pg_dumpall -U "$user" > "$DEST/$ns/postgres-dump.sql"
done

# Authentik
log "[authentik] copying media + templates"
authentik_pod=$(pod_for_deployment authentik authentik-server)
kubectl cp "authentik/${authentik_pod}:/data/media" "$DEST/authentik/media"
kubectl cp "authentik/${authentik_pod}:/templates" "$DEST/authentik/templates"

# Changedetection
log "[changedetection] copying datastore"
cd_pod=$(pod_for_deployment changedetection changedetection)
kubectl cp "changedetection/${cd_pod}:/datastore" "$DEST/changedetection/datastore"

# n8n
log "[n8n] copying .n8n"
n8n_pod=$(pod_for_deployment n8n n8n)
kubectl cp "n8n/${n8n_pod}:/home/node/.n8n" "$DEST/n8n/.n8n"

# trivy-operator's server (StatefulSet, client-server mode)
if kubectl get statefulset trivy-server -n trivy >/dev/null 2>&1; then
  log "[trivy-operator] copying scanner cache"
  kubectl cp "trivy/trivy-server-0:/home/scanner/.cache" "$DEST/trivy-operator/.cache"
else
  log "[trivy-operator] not deployed, skipping"
fi

# Vaultwarden
log "[vaultwarden] running built-in backup"
kubectl exec -n vaultwarden vaultwarden-0 -- /vaultwarden backup
kubectl cp vaultwarden/vaultwarden-0:/data "$DEST/vaultwarden/data"
kubectl exec -n vaultwarden vaultwarden-0 -- rm -rf /data/backups

# Hashicorp Vault raft snapshot, relies on the CLI session already logged in
log "[vault] taking raft snapshot"
if kubectl exec -n vault -c vault vault-0 -- vault operator raft snapshot save /tmp/vault.snap; then
  kubectl cp vault/vault-0:/tmp/vault.snap "$DEST/vault/vault.snap"
  kubectl exec -n vault -c vault vault-0 -- rm -f /tmp/vault.snap
else
  log "WARNING: vault snapshot failed, skipping vault backup this run"
fi

# restic: incremental, compressed, encrypted, 7-day retention
log "restic backup"
export RESTIC_PASSWORD_FILE

if [ ! -f "$RESTIC_REPO/config" ]; then
  restic -r "$RESTIC_REPO" init
fi

restic -r "$RESTIC_REPO" backup "$DEST"
restic -r "$RESTIC_REPO" forget --keep-within 7d --prune

log "Done"