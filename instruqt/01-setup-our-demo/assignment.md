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
- title: Vault OSS with DynamoDB
  type: terminal
  hostname: workstation
- title: Vault Enterprise
  type: terminal
  hostname: workstation
- title: Vault Enterprise with HSM
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
=====================

## Provision Infrastructure
```
terraform init
terraform apply -auto-approve
```

## Save Output, Copy to Vault OSS Node, and Access by SSH
```
terraform output -json > output.txt
scp -i privateKey.pem output.txt privateKey.pem ubuntu@$(cat output.txt | jq -r '.vault_ip.value'):~
```

## Save AWS Credentials to Vault HSM Node
```
echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> access_key.txt
echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> secret_key.txt
scp -i privateKey.pem access_key.txt secret_key.txt ubuntu@$(cat output.txt | jq -r '.vault_hsm_ip.value'):~
```

Vault OSS + DynamoDB
====================
Navigate to the `Vault OSS with DynamoDB` tab.

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

## Initialize and Unseal Vault, then Login
```
./run_vault.sh
```

## Enable and Configure Secret Engines

```
./config_vault.sh
```

## Copy files from Vault OSS to Vault Enterprise and Vault HSM Node
```
scp -i privateKey.pem vault_init.json ciphertext.txt output.txt lease_id.txt ubuntu@$(cat output.txt | jq -r '.vault_ent_ip.value'):~
```
```
scp -i privateKey.pem vault_init.json ciphertext.txt output.txt lease_id.txt ubuntu@$(cat output.txt | jq -r '.vault_hsm_ip.value'):~
```

## Stop Vault Service
```
sudo systemctl stop vault
```

Vault Enterprise with Integrated Storage
========================================
Navigate to the `Vault Enterprise` tab.

## SSH to Vault Enterprise Node
```
ssh -i privateKey.pem ubuntu@$(cat output.txt | jq -r '.vault_ent_ip.value')
```

## Configure and Start Vault Enterprise Service
```
chmod +x *.sh
./install_vault_ent.sh
```

## Migrate Vault OSS Data and Start Vault Enterprise Service
```
source ~/.bashrc
./migrate_data.sh
```

## Unseal Vault Ent Node with Original Unseal Key
```
./unseal_vault_ent.sh
```

## Login with Original Root Token, then Validate
```
./test_vault_ent.sh
```

Vault Enterprise with HSM Integration
=====================================
Navigate to the `Vault Enterprise with HSM` tab.

## SSH to Vault HSM Node
```
ssh -i privateKey.pem ubuntu@$(cat output.txt | jq -r '.vault_hsm_ip.value')
```

## Configure and Start Vault Service with HSM Integration
```
chmod +x *.sh
./insert_cloud_creds.sh
source ~/.bashrc
```

## Install awscli
```
sudo apt update -y
sudo apt install awscli jq -y
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
```
```
changePswd PRECO admin hashivault
```
```
logoutHSM
```
```
loginHSM CO admin hashivault
```
```
createUser CU vault Password1
```
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