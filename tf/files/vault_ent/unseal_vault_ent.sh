#!/usr/bin/env bash

vault operator unseal $(cat vault_init.json | jq -r '.unseal_keys_b64[0]')
sleep 5
vault status