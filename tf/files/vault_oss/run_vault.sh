#!/usr/bin/env bash

vault operator init -key-shares=1 -key-threshold=1 -format=json > ~/vault_init.json
vault operator unseal $(jq -r .unseal_keys_b64[0] < ~/vault_init.json)
sleep 5
vault login $(jq -r .root_token < ~/vault_init.json)