#!/usr/bin/env bash

vault login $(jq -r .root_token < ~/vault_init.json)
sleep 2

tput setaf 2; echo "RETRIEVE KEY-VALUE"
tput setaf 2; echo "=================="
sleep 2
vault kv get kv/hashitalks-secret
sleep 3

tput setaf 2; echo "DECRYPT CIPHERTEXT"
tput setaf 2; echo "=================="
sleep 2
tput setaf 6; echo "ciphertext = $(cat ciphertext.txt | jq -r '.data.ciphertext')"
sleep 2
tput setaf 6; echo "plaintext = $(vault write -field=plaintext transit/decrypt/hashitalks ciphertext=$(cat ciphertext.txt | jq -r '.data.ciphertext') | base64 --decode)"
sleep 3

tput setaf 2; echo "GENERATE CERTIFICATE"
tput setaf 2; echo "===================="
sleep 2
vault write pki/issue/hashitalks-dot-com \
    common_name=www.hashitalks.com
sleep 3

tput setaf 2; echo "LOOKUP FIRST MYSQL CREDENTIAL LEASE"
tput setaf 2; echo "==================================="
sleep 2
vault write sys/leases/lookup lease_id=$(cat lease_id.txt)
sleep 3

tput setaf 2; echo "GENERATE DYNAMIC MYSQL CREDENTIALS"
tput setaf 2; echo "=================================="
sleep 2
vault read database/creds/hashitalks-role
sleep 3

tput setaf 2; echo "LIST VAULT POLICIES"
tput setaf 2; echo "==================="
sleep 2
vault policy list
sleep 3

tput setaf 2; echo "TEST VAULT POLICY WITH USERPASS AUTH METHOD"
tput setaf 2; echo "==========================================="
sleep 2
vault login -method=userpass \
    username=nickyoung \
    password=hashitalks
sleep 2
tput setaf 2; echo "TEST SUCCESSFUL KV GET"
tput setaf 2; echo "======================"
sleep 2
vault kv get kv/hashitalks-secret
sleep 3
tput setaf 2; echo "TEST FAILING KV GET"
tput setaf 2; echo "==================="
sleep 2
vault kv get kv/hashitalks-speaker
sleep 3
tput setaf 6; echo "TESTS ON VAULT ENTERPRISE COMPLETE!"