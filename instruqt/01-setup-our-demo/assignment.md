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
terraform init
terraform apply -auto-approve
```

## Save Output, Copy to Vault Node, and SSH to Vault Node
```
terraform output -json > output.txt
scp -i privateKey.pem output.txt privateKey.pem ubuntu@$(terraform output -json | jq -r '.vault_ip.value'):~
```

## SSH to Vault OSS Node
```
ssh -i privateKey.pem ubuntu@$(terraform output -json | jq -r '.vault_ip.value')
```

## Configure and Start Vault Service
```
chmod +x *.sh
./install_vault.sh
```

## Check Vault status
```
source ~/.bashrc
vault status
```

## Initialize and Unseal Vault, then Login
```
./run_vault.sh
```

## Enable and Configure Secret Engines

```
./config_vault.sh
```

## Copy files from Vault OSS to Enterprise Node
```
scp -i privateKey.pem vault_init.json ciphertext.txt output.txt lease_id.txt ubuntu@$(cat output.txt | jq -r '.vault_ent_ip.value'):~
```

## Exit Vault OSS Node
```
exit
```

## SSH to Vault Enterprise Node
```
ssh -i privateKey.pem ubuntu@$(terraform output -json | jq -r '.vault_ent_ip.value')
```

## Configure and Start Vault Enterprise Service
```
chmod +x *.sh
./install_vault_ent.sh
source ~/.bashrc
```

## Copy Vault OSS Data and Start Vault Enterprise Service
```
sudo vault operator migrate -config migrate.hcl
sudo chown -R vault:vault /opt/vault/
sudo systemctl start vault
sudo systemctl status vault
```

## Unseal Vault Ent Node with Original Unseal Key
```
vault operator unseal $(jq -r .unseal_keys_b64[0] < vault_init.json)
sleep 5
vault status
```

## Login with Original Root Token
```
vault login $(jq -r .root_token < vault_init.json)
```

## Test for Expected Results
```
sleep 2
echo "RETRIEVE KEY-VALUE"
vault kv get kv/hashitalks-secret
sleep 2
echo "DECRYPT CIPHERTEXT"
vault write -field=plaintext transit/decrypt/hashitalks ciphertext=$(cat ciphertext.txt | jq -r '.data.ciphertext') | base64 --decode
sleep 2
echo "GENERATE CERTIFICATE"
vault write pki/issue/hashitalks-dot-com \
    common_name=www.hashitalks.com
sleep 2
echo "GENERATE DYNAMIC MYSQL CREDENTIALS"
vault read database/creds/hashitalks-role -format=json | jq -r '.lease_id' > lease_id.txt
sleep 2
echo "LOOKUP FIRST MYSQL CREDENTIAL LEASE"
vault write sys/leases/lookup lease_id=$(cat lease_id.txt)
```