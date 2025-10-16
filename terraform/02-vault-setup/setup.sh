#!/bin/bash

set -e

# Variables
BASE_DIR=$(readlink -f $(dirname ${0}))
VAULT_POD="vault-0"
VAULT_NAMESPACE="vault"
VAULT_ADDRESS="${VAULT_ADDRESS:-}"
VAULT_PORT="443"
POLICY_NAME="terraform-admin"
POLICY_FILE="terraform-admin.hcl"
TERRAFORM_FILE="terraform.tfvars"
AUTH_PATH="approle"
ROLE_NAME="terraform-role"

# Check if policy file exists
if [ ! -f "${BASE_DIR}/policies/$POLICY_FILE" ]; then
    echo "Error: Policy file '$POLICY_FILE' not found"
    exit 1
fi

# Copy policy file to pod
echo "Copying policy file to Vault pod..."
kubectl cp -n "${VAULT_NAMESPACE}" "${BASE_DIR}/policies/${POLICY_FILE}" "${VAULT_POD}:/tmp/${POLICY_FILE}"

# Execute all vault commands in the pod
echo "Setting up Vault authentication..."
kubectl exec -n "${VAULT_NAMESPACE}" "${VAULT_POD}" -- sh -c "
    # Create the policy
    vault policy write ${POLICY_NAME} /tmp/${POLICY_FILE}

    # Enable AppRole auth method if not exists
    if ! vault auth list | grep -q '^${AUTH_PATH}/'; then
        vault auth enable -path=${AUTH_PATH} -description='for Terraform and automation tools' approle
    fi

    # Create AppRole role
    vault write auth/${AUTH_PATH}/role/${ROLE_NAME} \
        token_policies=${POLICY_NAME} \
        token_ttl=5m \
        token_max_ttl=30m \
        secret_id_ttl=4h \
        secret_id_num_uses=0
"

# Get credentials
CREDENTIALS=$(kubectl exec -n "${VAULT_NAMESPACE}" "${VAULT_POD}" -- sh -c "
    ROLE_ID=\$(vault read -field=role_id auth/${AUTH_PATH}/role/${ROLE_NAME}/role-id)
    SECRET_ID=\$(vault write -field=secret_id -f auth/${AUTH_PATH}/role/${ROLE_NAME}/secret-id)    
    echo \"\${ROLE_ID}|\${SECRET_ID}\"
")

# Parse credentials
ROLE_ID=$(echo "$CREDENTIALS" | cut -d '|' -f1)
SECRET_ID=$(echo "$CREDENTIALS" | cut -d '|' -f2)

# Create terraform.tfvars file
cat > "$TERRAFORM_FILE" << EOF
login_approle_role_id   = "$ROLE_ID"
login_approle_secret_id = "$SECRET_ID"
vault_address           = "$VAULT_ADDRESS"
vault_port              = "$VAULT_PORT"
EOF

echo "Setup complete. Credentials saved to: $TERRAFORM_FILE"