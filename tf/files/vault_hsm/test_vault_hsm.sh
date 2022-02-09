#!/usr/bin/env bash

vault login $(jq -r .root_token < ~/vault_init.json)
sleep 2

tput setaf 6; echo "RETRIEVE KEY-VALUE"
tput setaf 6; echo "=================="
sleep 2
vault kv get kv/hashitalks-secret
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1

tput setaf 6; echo "DECRYPT CIPHERTEXT"
tput setaf 6; echo "=================="
sleep 2
tput setaf 6; echo "ciphertext = $(cat ciphertext.txt | jq -r '.data.ciphertext')"
sleep 2
tput setaf 6; echo "plaintext = $(vault write -field=plaintext transit/decrypt/hashitalks ciphertext=$(cat ciphertext.txt | jq -r '.data.ciphertext') | base64 --decode)"
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1

tput setaf 6; echo "GENERATE CERTIFICATE"
tput setaf 6; echo "===================="
sleep 2
vault write pki/issue/hashitalks-dot-com \
    common_name=www.hashitalks.com
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1

tput setaf 6; echo "LOOKUP FIRST MYSQL CREDENTIAL LEASE"
tput setaf 6; echo "==================================="
sleep 2
vault write sys/leases/lookup lease_id=$(cat lease_id.txt)
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1

tput setaf 6; echo "GENERATE DYNAMIC MYSQL CREDENTIALS"
tput setaf 6; echo "=================================="
sleep 2
vault read database/creds/hashitalks-role
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1

tput setaf 6; echo "LIST VAULT POLICIES"
tput setaf 6; echo "==================="
sleep 2
vault policy list
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1

tput setaf 6; echo "TEST VAULT POLICY WITH USERPASS AUTH METHOD"
tput setaf 6; echo "==========================================="
sleep 2
vault login -method=userpass \
    username=nickyoung \
    password=hashitalks
sleep 2
tput setaf 6; echo "TEST SUCCESSFUL KV GET"
tput setaf 6; echo "======================"
sleep 2
vault kv get kv/hashitalks-secret
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "TEST FAILING KV GET"
tput setaf 6; echo "==================="
sleep 2
vault kv get kv/hashitalks-speaker
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1

tput setaf 6; echo "RETRIEVE LATEST KEY-VALUE"
tput setaf 6; echo "========================="
sleep 3
vault kv get -format=json kv/hashitalks-secret | jq '.data.data'
sleep 3