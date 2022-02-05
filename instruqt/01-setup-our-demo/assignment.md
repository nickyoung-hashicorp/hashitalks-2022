---
slug: setup-our-demo
id: 36j0aeqeihed
type: challenge
title: "\U0001F3E1 HashiTalks 2022 - How to Migrate from Vault Open Source to Vault
  Enterprise"
teaser: |
  How to Migrate from Vault Open Source to Vault Enterprise
notes:
- type: text
  contents: |
    How to Migrate from Vault Open Source to Vault Enterprise
tabs:
- title: Shell
  type: terminal
  hostname: workstation
- title: Text Editor
  type: code
  hostname: workstation
  path: /root/hashitalks-2022/tf
- title: AWS Console
  type: service
  hostname: cloud-client
  path: /
  port: 80
difficulty: basic
timelimit: 28800
---

Deploy Infrastructure
==================================

## Provision
```
cd phase-1
terraform init
terraform apply -auto-approve
```

## Save output and copy to Vault node
```
terraform output -json > output.txt
scp -i privateKey.pem output.txt ubuntu@$(terraform output -json | jq -r '.vault_ip.value'):/home/ubuntu/output.txt
```

## Access Vault node with DynamoDB
```
ssh -i privateKey.pem ubuntu@$(terraform output -json | jq -r '.vault_ip.value')
```

## Configure Vault
```
chmod +x *.sh
./install_vault.sh
```

## Start Vault service
```
source ~/.bashrc
sudo systemctl enable vault
sudo systemctl start vault
sudo systemctl status vault
```

## Export Vault Address and check Vault status
```
export VAULT_ADDR='http://127.0.0.1:8200'
vault status
```

## Initialize and Unseal Vault
```
vault operator init -key-shares=1 -key-threshold=1 -format=json > vault_init.json
vault operator unseal $(jq -r .unseal_keys_b64[0] < vault_init.json)
```

## Login with the root token
```
vault login $(jq -r .root_token < vault_init.json)
```

## Enable and Configure Secret Engines

## KV
```
vault secrets enable -version=2 kv
vault kv put kv/hashitalks-secret year=2022 date=02-17-2022
vault kv get kv/hashitalks-secret
```

## Transit
```
vault secrets enable transit
vault write -f transit/keys/hashitalks
vault write transit/encrypt/hashitalks plaintext=$(base64 <<< "2022")
vault write transit/encrypt/hashitalks plaintext=$(base64 <<< "2022") -format=json > ciphertext.txt
cat ciphertext.txt | jq -r '.data.ciphertext'
vault write -field=plaintext transit/decrypt/hashitalks ciphertext=$(cat ciphertext.txt | jq -r '.data.ciphertext') | base64 --decode
```

## PKI
```
vault secrets enable pki
vault write pki/root/generate/internal \
    common_name=hashitalks.com \
    ttl=720h
vault write pki/config/urls \
    issuing_certificates="http://127.0.0.1:8200/v1/pki/ca" \
    crl_distribution_points="http://127.0.0.1:8200/v1/pki/crl"
vault write pki/roles/hashitalks-dot-com \
    allowed_domains=hashitalks.com \
    allow_subdomains=true \
    max_ttl=72h
vault write pki/issue/hashitalks-dot-com \
    common_name=www.hashitalks.com
```

## Database
```
vault secrets enable database
export RDS_ENDPOINT=
vault write database/config/my-mysql-database \
    plugin_name=mysql-database-plugin \
    connection_url="{{username}}:{{password}}@tcp(terraform-20220205032646469400000001.cirlxode7244.us-west-1.rds.amazonaws.com:3306)/" \
    allowed_roles="hashitalks-role" \
    username="hashitalks2022" \
    password="migrateVault!"
vault write database/roles/hashitalks-role \
    db_name=my-mysql-database \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="8h" \
    max_ttl="24h"
vault read database/creds/hashitalks-role
```
# [[[[[[[[TODO]]]]]]]]]]]]]

## Destroy
```
terraform destroy -auto-approve
```