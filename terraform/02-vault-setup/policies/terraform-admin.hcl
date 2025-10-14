# Secret engine mounts management
path "sys/mounts/*" {
  capabilities = ["create", "update", "delete", "list"]
}
path "sys/mounts" {
  capabilities = ["read", "list"]
}
path "sys/mounts/*/tune" {
  capabilities = ["create", "update", "delete"]
}

# Auth management
path "sys/auth/*" {
  capabilities = ["create", "update", "delete", "sudo", "list"]
}
path "sys/auth" {
  capabilities = ["read", "list"]
}
path "sys/auth/*/tune" {
  capabilities = ["create", "update", "delete"]
}

# ACL policy management
path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
path "sys/policies/acl" {
  capabilities = ["read", "list"]
}
# Allow the machine to attach policies
path "auth/*/role/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Health check (check the status of Vault)
path "sys/health" {
  capabilities = ["read"]
}