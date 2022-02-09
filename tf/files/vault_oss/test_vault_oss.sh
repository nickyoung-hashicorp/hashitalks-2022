#!/usr/bin/env bash

vault login $(jq -r .root_token < ~/vault_init.json)
sleep 2

tput setaf 2; echo "RETRIEVE KEY-VALUE"
tput setaf 2; echo "=================="
sleep 1
vault kv get kv/hashitalks-secret
sleep 2

tput setaf 2; echo "DECRYPT CIPHERTEXT"
tput setaf 2; echo "=================="
sleep 1
vault write -field=plaintext transit/decrypt/hashitalks ciphertext=$(cat ~/ciphertext.txt | jq -r '.data.ciphertext') | base64 --decode
sleep 2

tput setaf 2; echo "GENERATE CERTIFICATE"
tput setaf 2; echo "===================="
sleep 1
vault write pki/issue/hashitalks-dot-com \
    common_name=www.hashitalks.com
sleep 2

tput setaf 2; echo "LOOKUP FIRST MYSQL CREDENTIAL LEASE"
tput setaf 2; echo "==================================="
sleep 1
vault write sys/leases/lookup lease_id=$(cat lease_id.txt)
sleep 2

tput setaf 2; echo "GENERATE DYNAMIC MYSQL CREDENTIALS"
tput setaf 2; echo "=================================="
sleep 1
vault read database/creds/hashitalks-role

tput setaf 2; echo "LIST VAULT POLICIES"
tput setaf 2; echo "==================="
sleep 1
vault policy list
sleep 2

tput setaf 2; echo "TEST VAULT POLICY"
tput setaf 2; echo "================="
sleep 1
export VAULT_TOKEN="$(vault token create -field token -policy=hashitalks-policy)"