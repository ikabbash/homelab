path "homelab/infra/kv-secret/data/*" {
  capabilities = ["read", "list"]
}

path "homelab/infra/kv-secret/metadata/*" {
  capabilities = ["read", "list"]
}