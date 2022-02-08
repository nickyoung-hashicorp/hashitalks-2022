#!/usr/bin/env bash

tput setaf 6; echo "DECRYPT CIPHERTEXT"
tput setaf 6; echo "=================="
sleep 2
tput setaf 6; echo "ciphertext = $(cat ciphertext.txt | jq -r '.data.ciphertext')"
sleep 2
tput setaf 6; echo "plaintext = $(vault write -field=plaintext transit/decrypt/hashitalks ciphertext=$(cat ciphertext.txt | jq -r '.data.ciphertext') | base64 --decode)"
sleep 2
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1

tput setaf 6; echo "GENERATE CERTIFICATE"
tput setaf 6; echo "===================="
sleep 3
tput setaf 6; vault write pki/issue/hashitalks-dot-com \
    common_name=www.hashitalks.com
sleep 2
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1

tput setaf 6; echo "LOOKUP FIRST MYSQL CREDENTIAL LEASE"
tput setaf 6; echo "==================================="
sleep 3
vault write sys/leases/lookup lease_id=$(cat lease_id.txt)
sleep 2
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1
tput setaf 6; echo "."
sleep 1

tput setaf 6; echo "GENERATE NEW MYSQL CREDENTIALS"
tput setaf 6; echo "=================================="
sleep 3
vault read database/creds/hashitalks-role
sleep 2
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