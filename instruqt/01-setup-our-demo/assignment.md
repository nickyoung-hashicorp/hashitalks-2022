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

## Save Output, Copy to Vault Node, and SSH to Vault Node
```
terraform output -json > output.txt
scp -i privateKey.pem output.txt ubuntu@$(terraform output -json | jq -r '.vault_ip.value'):/home/ubuntu/output.txt
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

