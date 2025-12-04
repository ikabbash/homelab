#!/bin/bash

# Use this script if you have KeePassXC
# Entries will need to be stored at homelab/vault with entry names from unseal_key1 to unseal_key5
# Usage: ./unseal.sh /path/to/keepass.kdbx

set -euo pipefail

# /path/to/your/keepass.kdbx
DB_FILE="$1"
# vault unseal entries
BASE_PATH="homelab/vault"
VAULT_NAMESPACE=$(terraform output -state=../02-core-services/terraform.tfstate -raw vault_namespace)

# Prompt for master password (hidden input)
read -s -p "Master password for ${DB_FILE}: " MASTER_PW
echo -e "\n"

# Test if master password is correct by trying to show the first entry quietly
if ! echo "${MASTER_PW}" | keepassxc-cli show -q "${DB_FILE}" "${BASE_PATH}/unseal_key1" >/dev/null 2>&1; then
  echo "Error: incorrect password or database not accessible"
  exit 1
fi

# Check that all entries exist
for i in {1..5}; do
  ENTRY_PATH="${BASE_PATH}/unseal_key${i}"
  if ! echo "${MASTER_PW}" | keepassxc-cli show -q "${DB_FILE}" "${ENTRY_PATH}" >/dev/null 2>&1; then
    echo "Error: entry not found -> ${ENTRY_PATH}"
    exit 1
  fi
done

echo -e "Unsealing...\n"

# Unseal with each entry (using the first 3 keys)
for i in {1..3}; do
  ENTRY_PATH="${BASE_PATH}/unseal_key${i}" # Entry names
  UNSEAL_KEY=$(echo "${MASTER_PW}" | keepassxc-cli show -q -s -a password "${DB_FILE}" "${ENTRY_PATH}")
  kubectl exec -it -n "${VAULT_NAMESPACE}" vault-0 -- vault operator unseal "${UNSEAL_KEY}"
  echo
done
