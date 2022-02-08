#!/usr/bin/env bash

tput setaf 7; echo "CONFIGURING KEY-VALUE SECRETS ENGINE"
tput setaf 7; echo "===================================="
sleep 1
vault secrets enable -version=2 kv
vault kv put kv/hashitalks-secret year=2022 date=02-17-2022
vault kv put kv/hashitalks-speaker name="Nick Young"
vault kv get kv/hashitalks-secret

tput setaf 7; echo "CONFIGURING TRANSIT SECRETS ENGINE"
tput setaf 7; echo "=================================="
sleep 1
vault secrets enable transit
vault write -f transit/keys/hashitalks
vault write transit/encrypt/hashitalks plaintext=$(base64 <<< "Welcome to HashiTalks 2022!")
vault write transit/encrypt/hashitalks plaintext=$(base64 <<< "Welcome to HashiTalks 2022!") -format=json > ciphertext.txt
cat ciphertext.txt | jq -r '.data.ciphertext'
tput setaf 7; echo "Encrypting plaintext \"Welcome to HashiTalks 2022!\""
sleep 1
tput setaf 7; echo "into ciphertext $(cat ciphertext.txt)"
sleep 1
tput setup 7; echo "And decrypting ciphertext back to plaintext"
vault write -field=plaintext transit/decrypt/hashitalks ciphertext=$(cat ciphertext.txt | jq -r '.data.ciphertext') | base64 --decode
sleep 2

tput setaf 7; echo "CONFIGURING PKI SECRETS ENGINE"
tput setaf 7; echo "=============================="
sleep 1
vault secrets enable pki
vault write pki/root/generate/internal \
    common_name=hashitalks.com \
    ttl=720h
vault write pki/config/urls \
    issuing_certificates="http://127.0.0.1:8200/v1/pki/ca" \
    crl_distribution_points="http://127.0.0.1:8200/v1/pki/crl"
vault write pki/roles/hashitalks-dot-com \
    allowed_domains=hashitalks.com \
    allow_subdomains=true \
    max_ttl=72h
vault write pki/issue/hashitalks-dot-com \
    common_name=www.hashitalks.com

tput setaf 7; echo "CONFIGURING DATABASE SECRETS ENGINE"
tput setaf 7; echo "==================================="
sleep 1
vault secrets enable database
vault write database/config/my-mysql-database \
    plugin_name=mysql-database-plugin \
    connection_url="{{username}}:{{password}}@tcp($(cat output.txt | jq -r '.rds_endpoint.value'))/" \
    allowed_roles="hashitalks-role" \
    username="hashitalks2022" \
    password="migrateVault!"
vault write database/roles/hashitalks-role \
    db_name=my-mysql-database \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="8h" \
    max_ttl="24h"
tput setaf 7; echo "GENERATE MYSQL DATABASE CREDENTIALS AND STORE LEASE ID"
tput setaf 7; echo "======================================================"
sleep 1
vault read database/creds/hashitalks-role -format=json | jq -r '.lease_id' > lease_id.txt
sleep 1
tput setaf 7; echo "Lease ID = $(cat lease_id.txt)"
sleep 1

tput setaf 7; echo "CREATE VAULT POLICY"
tput setaf 7; echo "==================="
sleep 1
vault policy write hashitalks-policy - << EOF
path "kv/data/*" {
  capabilities = ["create", "update","read"]
}

path "kv/data/hashitalks-speaker" {
  capabilities = ["deny"]
}
EOF
sleep 1
tput setaf 7; echo "CREAT USERPASS AUTH METHOD WITH \"hashitalks-policy\""
tput setaf 7; echo "====================================================="
sleep 1
vault auth enable userpass
vault write auth/userpass/users/nickyoung \
    password=hashitalks \
    policies=hashitalks-policy
sleep 1
tput setaf 7; echo "LOGIN WITH USERPASS AUTH METHOD"
tput setaf 7; echo "==============================="
sleep 1
vault login -method=userpass \
    username=nickyoung \
    password=hashitalks
sleep 1
tput setaf 7; echo "TEST SUCCESSFUL KV GET"
tput setaf 7; echo "======================"
sleep 1
vault kv get kv/hashitalks-secret
sleep 1
tput setaf 7; echo "TEST FAILING KV GET"
tput setaf 7; echo "==================="
sleep 1
vault kv get kv/hashitalks-speaker
sleep 2


