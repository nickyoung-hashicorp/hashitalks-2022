#!/usr/bin/env bash

vault operator unseal $(jq -r .unseal_keys_b64[0] < vault_init.json)
sleep 5
vault status