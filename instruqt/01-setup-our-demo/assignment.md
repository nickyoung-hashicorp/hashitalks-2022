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
- title: Workstation
  type: terminal
  hostname: workstation
- title: OSS
  type: terminal
  hostname: workstation
- title: ENT
  type: terminal
  hostname: workstation
- title: HSM
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

Provision Infrastructure
========================

## Provision Infrastructure
```
terraform init
terraform apply -auto-approve
```

## Save Output
```
chmod +x *.sh
./save_output.sh
```

Setup Vault OSS with DynamoDB
===============================
## Select the `OSS` tab

## SSH to Vault OSS Node
```
ssh -i privateKey.pem ubuntu@$(cat output.txt | jq -r '.vault_ip.value')
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

## Run, Configure, and Test Vault OSS
```
./run_vault.sh
./config_vault.sh
./test_vault.sh
```

## Copy files from Vault OSS to Vault Enterprise and Vault HSM Node
```
scp -i privateKey.pem vault_init.json ciphertext.txt lease_id.txt ubuntu@$(cat output.txt | jq -r '.vault_ent_ip.value'):~
```
```
scp -i privateKey.pem vault_init.json ciphertext.txt lease_id.txt ubuntu@$(cat output.txt | jq -r '.vault_hsm_ip.value'):~
```

Setup Vault Enterprise
===============================
## Navigate to the `ENT` tab.

## SSH to Vault Enterprise Node
```
ssh -i privateKey.pem ubuntu@$(cat output.txt | jq -r '.vault_ent_ip.value')
```

## Configure and Start Vault Enterprise Service
```
chmod +x *.sh
./install_vault_ent.sh
```
```
source ~/.bashrc
```

Setup Vault Enterprise with HSM
=================================
## Navigate to the `HSM` tab.

## SSH to Vault HSM Node
```
ssh -i privateKey.pem ubuntu@$(cat output.txt | jq -r '.vault_hsm_ip.value')
```

## Configure and Start Vault Service with HSM Integration
```
sudo apt update -y
sudo apt install awscli jq unzip -y
```
```
chmod +x *.sh
source ~/.bashrc
```

## Export Environment Variables
```
export HSM_CLUSTER_ID=$(cat output.txt | jq -r .hsm_cluster_id.value)
export AWS_DEFAULT_REGION=us-west-2
```

## Generate CSR
```
aws cloudhsmv2 describe-clusters --filters clusterIds=${HSM_CLUSTER_ID} \
  --output text --query 'Clusters[].Certificates.ClusterCsr' > ClusterCsr.csr
```

## Generate Key
```
openssl genrsa -aes256 -out customerCA.key 2048
```

## Generate CA Cert
```
openssl req -new -x509 -days 3652 -key customerCA.key -out customerCA.crt
```

## Generate HSM Cert
```
openssl x509 -req -days 3652 -in ClusterCsr.csr \
  -CA customerCA.crt -CAkey customerCA.key -CAcreateserial \
  -out CustomerHsmCertificate.crt
```

## Initialize HSM Cluster
```
aws cloudhsmv2 initialize-cluster --cluster-id ${HSM_CLUSTER_ID} \
  --signed-cert file://CustomerHsmCertificate.crt \
  --trust-anchor file://customerCA.crt
```

## Check periodically until it shows `INITIALIZED`
```
watch aws cloudhsmv2 describe-clusters \
      --filters clusterIds=${HSM_CLUSTER_ID} \
      --output text \
      --query 'Clusters[].State'
```
Press `Ctrl+C` to exit out of this watch.

## Find and Save the IP address of the CloudHSM
```
export HSM_IP=$(aws cloudhsmv2 describe-clusters \
      --filters clusterIds=${HSM_CLUSTER_ID} \
      --query 'Clusters[].Hsms[] .EniIp' | jq -r .[])
```

## Install the HSM Client
```
wget https://s3.amazonaws.com/cloudhsmv2-software/CloudHsmClient/Bionic/cloudhsm-client_latest_u18.04_amd64.deb
sudo apt install ./cloudhsm-client_latest_u18.04_amd64.deb -y
```
```
sudo /opt/cloudhsm/bin/configure -a $HSM_IP
sudo mv customerCA.crt /opt/cloudhsm/etc/customerCA.crt
```

## Configure HSM User
```
/opt/cloudhsm/bin/cloudhsm_mgmt_util /opt/cloudhsm/etc/cloudhsm_mgmt_util.cfg
```
```
loginHSM PRECO admin password
changePswd PRECO admin hashivault
```
Press `y` then `Enter` when prompted.

```
logoutHSM
loginHSM CO admin hashivault
createUser CU vault Password1
```
Press `y` then `Enter` when prompted.

```
quit
```

## Install PKCS #11 Library
```
sudo service cloudhsm-client start
wget https://s3.amazonaws.com/cloudhsmv2-software/CloudHsmClient/Bionic/cloudhsm-client-pkcs11_latest_u18.04_amd64.deb
sudo apt install ./cloudhsm-client-pkcs11_latest_u18.04_amd64.deb -y
```

## Install Vault Enterprise with HSM Integration
```
./install_vault_hsm.sh
```

## Initialize and Unseal Vault Enterprise with HSM Integration
```
echo 'export VAULT_ADDR="http://127.0.0.1:8200"' >> ~/.bashrc
source ~/.bashrc
./run_vault_hsm.sh
```

Start Demo
==========
## Navigate to the `OSS` tab.

## Show Test Script
```
vim test_vault.sh
```


## Test Vault Responses
```
test_vault.sh
```

## Stop Vault Service
```
sudo systemctl stop vault
```

## Take a DynamoDB Backup and Store as a Variable
```
BACKUP_ARN=$(aws dynamodb create-backup \
    --table-name vault-backend \
    --backup-name hashitalks-dynamo-backup | jq -r '.BackupDetails.BackupArn')
```

## Check the Status of the Backup, looking for `AVAILABLE`
```
aws dynamodb describe-backup \
    --backup-arn $BACKUP_ARN | jq '.BackupDescription.BackupDetails.BackupStatus'
```

## Navigate to the `ENT` tab.

## Show Migrate Script
```
vim migrate_data.sh
```


## Migrate Vault OSS Data and Start Vault Enterprise Service
```
migrate_data.sh
```

## Unseal Vault Ent Node with Original Unseal Key
```
unseal_vault_ent.sh
```

## Login with Original Root Token, then Validate
```
test_vault_ent.sh
```

## With Testing Complete, Setup DR Replication

## Setup Vault Enterprise as the DR Primary Cluster
```
vault login $(jq -r .root_token < vault_init.json)
vault write -f /sys/replication/dr/primary/enable
```

## Generate DR Token
```
vault write -format=json /sys/replication/dr/primary/secondary-token id="vault-enterprise-hsm" | jq -r '.wrap_info .token' > primary_dr_token.txt
```

## Copy DR Token to Vault with HSM
```
scp -i privateKey.pem primary_dr_token.txt ubuntu@$(cat output.txt | jq -r '.vault_hsm_ip.value'):~
```

## Navigate to the `HSM` tab.

## Enable Vault Enterprise with HSM Integration as the DR Secondary Cluster
```
vault write /sys/replication/dr/secondary/enable token=$(cat primary_dr_token.txt)
```

## Check Replication State, Looking for `"stream-wals"`
```
vault read -format=json sys/replication/status | jq '.data.dr.state'
```

## Navigate to the `ENT` tab.

## Check Replication State, Looking for `"running"`
```
vault read -format=json sys/replication/status | jq '.data.dr.state'
```

## Write Additional KV Data
```
vault kv put kv/hashitalks-secret message="HashiTalks Demo - Complete!"
vault kv get kv/hashitalks-secret
```

## Check Replication State, Looking for `"running"`
```
vault read -format=json sys/replication/status | jq '.data.dr.state'
```

## Navigate to the `HSM` tab.

## Check Replication State, Looking for `"stream-wals"`
```
vault read -format=json sys/replication/status | jq '.data.dr.state'
```

## Generate DR Operation Token
```
DR_OTP=$(vault operator generate-root -dr-token -generate-otp)
NONCE=$(vault operator generate-root -dr-token -init -otp=${DR_OTP} | grep -i nonce | awk '{print $2}')
```

## Validate DR Process Started, looking for `"started": true`
```
curl -s http://127.0.0.1:8200/v1/sys/replication/dr/secondary/generate-operation-token/attempt | jq
```

## Provide Primary Unseal Key and Decode Encoded Token
```
PRIMARY_UNSEAL_KEY=$(jq -r .unseal_keys_b64[0] < vault_init.json)
ENCODED_TOKEN=$(vault operator generate-root -dr-token -nonce=$NONCE $PRIMARY_UNSEAL_KEY | grep -i encoded | awk '{print $3}' )
DR_OPERATION_TOKEN=$(vault operator generate-root -dr-token -otp=$DR_OTP -decode=$ENCODED_TOKEN)
```

## Navigate to the `ENT` tab.

## Check the Cluster's mode is `"primary"`
```
vault read -format=json sys/replication/status | jq '.data.dr'
```

## Disable Replication on Vault Enterprise (DR Primary)
```
vault write -f /sys/replication/dr/primary/disable
```

## Check again, where the Cluster's mode is now `"disabled"`
```
vault read -format=json sys/replication/status | jq '.data.dr'
```

## Navigate to the `HSM` tab.

## Check Replication Status, looking for `"connection_status": "disconnected"`
```
vault read -format=json sys/replication/status | jq '.data.dr.primaries'
```

## Promote Vault Enterprise with HSM (DR Secondary)
```
vault write -f /sys/replication/dr/secondary/promote dr_operation_token=${DR_OPERATION_TOKEN}
```

## Check Replication Status, where the mode is `"primary"`
```
vault read -format=json sys/replication/status | jq '.data.dr'
```

## Test Vault Login with Original Root Token
```
vault login $(jq -r .root_token < vault_init.json)
```

## Final Testing
```
test_vault_hsm.sh
```
