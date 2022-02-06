sudo apt install awscli -y

export HSM_CLUSTER_ID=$(cat output.txt | jq -r .hsm_cluster_id.value)
export AWS_DEFAULT_REGION=us-west-2
export AWS_ACCESS_KEY_ID=$(cat access_key.txt)
export AWS_SECRET_ACCESS_KEY=$(cat secret_key.txt)


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
aws cloudhsmv2 describe-clusters \
      --filters clusterIds=${HSM_CLUSTER_ID} \
      --query 'Clusters[].Hsms[] .EniIp'