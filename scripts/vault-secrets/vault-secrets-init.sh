#!/bin/bash

set -euo pipefail

CONFIG_FILE="${1:-vault-secrets.sh}"

# Comment the function if you already have Vault CLI
vault() {
    kubectl exec -it -n vault vault-0 -- vault "$@"
}

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config file '$CONFIG_FILE' not found." >&2
    exit 1
fi

secrets_written=0

generate() {
    openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c "$1"
}

# secret <path> key=value key=value ...
secret() {
    local path="$1"
    shift

    echo "Writing secret to: $path"
    vault kv put "$path" "$@"

    secrets_written=$((secrets_written + 1))
}

# shellcheck source=/dev/null
source "$CONFIG_FILE"

echo "Done. Wrote $secrets_written secret(s)."