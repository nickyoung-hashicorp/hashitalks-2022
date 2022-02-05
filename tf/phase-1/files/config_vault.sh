echo "Configuring Key-Value Secrets Engine"
sleep 1
vault secrets enable -version=2 kv
vault kv put kv/hashitalks-secret year=2022 date=02-17-2022
vault kv get kv/hashitalks-secret

echo "Configuring Transit Secrets Engine"
sleep 1
vault secrets enable transit
vault write -f transit/keys/hashitalks
vault write transit/encrypt/hashitalks plaintext=$(base64 <<< "Welcome to HashiTalks 2022!")
vault write transit/encrypt/hashitalks plaintext=$(base64 <<< "Welcome to HashiTalks 2022!") -format=json > ciphertext.txt
cat ciphertext.txt | jq -r '.data.ciphertext'
vault write -field=plaintext transit/decrypt/hashitalks ciphertext=$(cat ciphertext.txt | jq -r '.data.ciphertext') | base64 --decode

echo "Configuring PKI Secrets Engine"
sleep 1
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

echo "Configuring Database Secrets Engine"
sleep 1
vault secrets enable database
export RDS_ENDPOINT=
vault write database/config/my-mysql-database \
    plugin_name=mysql-database-plugin \
    connection_url="{{username}}:{{password}}@tcp($(cat output.txt | jq -r '.rds_endpoint.value'))/" \
    allowed_roles="hashitalks-role" \
    username="hashitalks2022" \
    password="migrateVault!"
vault write database/roles/hashitalks-role \
    db_name=my-mysql-database \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="8h" \
    max_ttl="24h"
vault read database/creds/hashitalks-role
export LEASE_ID=$(vault read database/creds/hashitalks-role -format=json | jq -r .lease_id)
vault write sys/leases/lookup lease_id=$LEASE_ID