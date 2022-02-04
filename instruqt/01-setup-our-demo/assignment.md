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

## Access Vault node with DynamoDB
```
ssh -t ubuntu@$(terraform output -json | jq -r '.vault_ip.value') 'export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID >> ~/.bashrc; bash'
ssh -t ubuntu@$(terraform output -json | jq -r '.vault_ip.value') 'export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY >> ~/.bashrc; bash'
ssh -i privateKey.pem ubuntu@$(terraform output -json | jq -r '.vault_ip.value')
```

## Destroy
```
terraform destroy -auto-approve
```