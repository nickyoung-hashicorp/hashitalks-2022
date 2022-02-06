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

# Provision Infrastructure
```
terraform init
terraform apply -auto-approve
```

# Vault OSS + DynamoDB

### Save Output, Copy to Vault OSS Node, and Access by SSH
```
terraform output -json > output.txt
scp -i privateKey.pem output.txt privateKey.pem ubuntu@$(cat output.txt | jq -r '.vault_ip.value'):~
```

### Save AWS Credentials to Vault Enterprise Node
```
echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> access_key.txt
echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> secret_key.txt
scp -i privateKey.pem access_key.txt secret_key.txt ubuntu@$(cat output.txt | jq -r '.vault_hsm_ip.value'):~
```

### SSH to Vault OSS Node
```
ssh -i privateKey.pem ubuntu@$(cat output.txt | jq -r '.vault_ip.value')
```

### Configure and Start Vault Service
```
chmod +x *.sh
./install_vault.sh
```

### Check Vault status
```
source ~/.bashrc
vault status
```

### Initialize and Unseal Vault, then Login
```
./run_vault.sh
```

### Enable and Configure Secret Engines

```
./config_vault.sh
```

### Copy files from Vault OSS to Vault Enterprise and Vault HSM Node
```
scp -i privateKey.pem vault_init.json ciphertext.txt output.txt lease_id.txt ubuntu@$(cat output.txt | jq -r '.vault_ent_ip.value'):~
```
```
scp -i privateKey.pem vault_init.json ciphertext.txt output.txt lease_id.txt ubuntu@$(cat output.txt | jq -r '.vault_hsm_ip.value'):~
```

### Stop Vault Service and Exit
```
sudo systemctl stop vault
exit
```

# Vault Enterprise with Integrated Storage

### SSH to Vault Enterprise Node
```
ssh -i privateKey.pem ubuntu@$(cat output.txt | jq -r '.vault_ent_ip.value')
```

### Configure and Start Vault Enterprise Service
```
chmod +x *.sh
./install_vault_ent.sh
```

### Migrate Vault OSS Data and Start Vault Enterprise Service
```
source ~/.bashrc
./migrate_data.sh
```

### Unseal Vault Ent Node with Original Unseal Key
```
./unseal_vault_ent.sh
```

### Login with Original Root Token, then Validate
```
./test_vault_ent.sh
```

### Exit Vault Enterprise Node
```
exit
```

# Vault Enterprise with HSM Integration

### SSH to Vault HSM Node
```
ssh -i privateKey.pem ubuntu@$(cat output.txt | jq -r '.vault_hsm_ip.value')
```

### Configure and Start Vault Service with HSM Integration
```
cat access_key.txt >> ~/.bashrc
cat secret_key.txt >> ~/.bashrc
source ~/.bashrc
chmod +x *.sh
./config_vault_hsm.sh
```

```
./install_vault_hsm.sh
source ~/.bashrc
```