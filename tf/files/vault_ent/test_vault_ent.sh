#!/usr/bin/env bash

vault login $(jq -r .root_token < vault_init.json)
sleep 2

tput setaf 6; echo "RETRIEVE KEY-VALUE"
vault kv get kv/hashitalks-secret
sleep 2

tput setaf 6; echo "DECRYPT CIPHERTEXT"
vault write -field=plaintext transit/decrypt/hashitalks ciphertext=$(cat ciphertext.txt | jq -r '.data.ciphertext') | base64 --decode
sleep 2

tput setaf 6; echo "GENERATE CERTIFICATE"
vault write pki/issue/hashitalks-dot-com \
    common_name=www.hashitalks.com
sleep 2

tput setaf 6; echo "LOOKUP FIRST MYSQL CREDENTIAL LEASE"
vault write sys/leases/lookup lease_id=$(cat lease_id.txt)
sleep 2

tput setaf 6; echo "GENERATE DYNAMIC MYSQL CREDENTIALS"
vault read database/creds/hashitalks-role