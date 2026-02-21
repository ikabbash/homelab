# Permit creating a new token that is a child of the one given (Terraform won't work without it)
path "auth/token/create"
{
  capabilities = ["update"]
}

# Secret engine mounts management
path "sys/mounts/homelab/*" {
  capabilities = ["create", "update", "delete", "list", "read"]
}

# ACL policy management
path "sys/policies/acl/*" {
  capabilities = ["create", "update", "delete", "list", "read"]
}

# Auth management
path "sys/mounts/auth/*" {
  capabilities = ["list", "read"]
}
# Kubernetes auth setup
path "sys/auth/kubernetes/vso" {
  capabilities = ["create", "update", "delete", "sudo"]
}
path "auth/kubernetes/vso/*" {
  capabilities = ["create", "update", "delete", "read"]
}

# Write access to secrets
path "homelab/infra/kv-secret/*" {
  capabilities = ["create", "update", "delete", "read"]
}

# Access to audit
path "sys/audit/*" {
  capabilities = ["create", "update", "read", "list", "delete", "sudo"]
}
path "sys/audit" {
  capabilities = ["read", "list", "sudo"]
}