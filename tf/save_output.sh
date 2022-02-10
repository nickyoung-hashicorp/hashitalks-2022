#!/usr/bin/env bash

terraform output -json > output.txt
echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> access_key.txt
echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> secret_key.txt
scp -i privateKey.pem output.txt access_key.txt secret_key.txt privateKey.pem ubuntu@$(cat output.txt | jq -r '.vault_ip.value'):~
scp -i privateKey.pem output.txt access_key.txt secret_key.txt privateKey.pem ubuntu@$(cat output.txt | jq -r '.vault_ent_ip.value'):~
scp -i privateKey.pem output.txt access_key.txt secret_key.txt ubuntu@$(cat output.txt | jq -r '.vault_hsm_ip.value'):~