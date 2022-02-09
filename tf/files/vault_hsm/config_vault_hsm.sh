#!/usr/bin/env bash

# sudo apt update -y
# sudo apt install awscli jq -y

export HSM_CLUSTER_ID=$(cat output.txt | jq -r .hsm_cluster_id.value)
export AWS_DEFAULT_REGION=us-west-2


aws cloudhsmv2 describe-clusters --filters clusterIds=${HSM_CLUSTER_ID} \
  --output text --query 'Clusters[].Certificates.ClusterCsr' > ClusterCsr.csr

openssl genrsa -aes256 -out customerCA.key 2048

openssl req -new -x509 -days 3652 -key customerCA.key -out customerCA.crt

openssl x509 -req -days 3652 -in ClusterCsr.csr \
  -CA customerCA.crt -CAkey customerCA.key -CAcreateserial \
  -out CustomerHsmCertificate.crt

aws cloudhsmv2 initialize-cluster --cluster-id ${HSM_CLUSTER_ID} \
  --signed-cert file://CustomerHsmCertificate.crt \
  --trust-anchor file://customerCA.crt

# Check periodically until it shows INITIALIZED
aws cloudhsmv2 describe-clusters \
      --filters clusterIds=${HSM_CLUSTER_ID} \
      --output text \
      --query 'Clusters[].State'

#Finds the IP address of the CloudHSM
export HSM_IP=$(aws cloudhsmv2 describe-clusters \
      --filters clusterIds=${HSM_CLUSTER_ID} \
      --query 'Clusters[].Hsms[] .EniIp' | jq -r .[])


wget https://s3.amazonaws.com/cloudhsmv2-software/CloudHsmClient/Bionic/cloudhsm-client_latest_u18.04_amd64.deb

sudo apt install ./cloudhsm-client_latest_u18.04_amd64.deb -y

sudo /opt/cloudhsm/bin/configure -a $HSM_IP

sudo mv customerCA.crt /opt/cloudhsm/etc/customerCA.crt

/opt/cloudhsm/bin/cloudhsm_mgmt_util /opt/cloudhsm/etc/cloudhsm_mgmt_util.cfg

loginHSM PRECO admin password

changePswd PRECO admin hashivault

logoutHSM

loginHSM CO admin hashivault

createUser CU vault Password1

quit

# Install PKCS #11 Library
sudo service cloudhsm-client start

wget https://s3.amazonaws.com/cloudhsmv2-software/CloudHsmClient/Bionic/cloudhsm-client-pkcs11_latest_u18.04_amd64.deb

sudo apt install ./cloudhsm-client-pkcs11_latest_u18.04_amd64.deb -y