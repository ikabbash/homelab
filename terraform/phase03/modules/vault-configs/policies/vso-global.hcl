path "homelab/infra/kv-secret/data/*" {
  capabilities = ["read"]
}

path "homelab/infra/kv-secret/metadata/*" {
  capabilities = ["read"]
}

path "homelab/apps/kv-secret/data/*" {
  capabilities = ["read"]
}

path "homelab/apps/kv-secret/metadata/*" {
  capabilities = ["read"]
}