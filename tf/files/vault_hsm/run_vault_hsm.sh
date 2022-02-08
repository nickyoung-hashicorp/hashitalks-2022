#!/usr/bin/env bash

vault operator init -key-shares=1 -key-threshold=1 -recovery-shares=1 -recovery-threshold=1 -format=json > vault_hsm_init.json
sleep 10
vault login $(jq -r .root_token < vault_hsm_init.json)