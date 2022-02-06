# DynamoDB (Source) Backend
storage_source "dynamodb" {
  ha_enabled = "true"
  region     = "us-west-2"
  table      = "vault-backend"
}

# Integrated Storage (Destination) Backend
storage_destination "raft" {
  path = "/opt/vault"
  node_id = "vault-1"
}
cluster_addr = "http://127.0.0.1:8201"