#!/usr/bin/env bash

# echo "Running updates and installing unzip, jq"
sudo apt update -y
sudo apt install unzip jq -y

echo "Installing Vault Enterprise"
# Setup vault enterprise as server
set -e

# USER VARS
VAULT_VERSION="1.9.3"
NODE_NAME="${1:-$(hostname -s)}"
VAULT_DIR=/usr/local/bin
VAULT_CONFIG_DIR=/etc/vault.d
VAULT_DATA_DIR=/opt/vault

# CALCULATED VARS
VAULT_PATH=${VAULT_DIR}/vault
VAULT_ZIP="vault_${VAULT_VERSION}+ent_linux_amd64.zip"
VAULT_URL="https://releases.hashicorp.com/vault/${VAULT_VERSION}+ent/${VAULT_ZIP}"

# CHECK DEPENDANCIES AND SET NET RETRIEVAL TOOL
if ! unzip -h 2&> /dev/null; then
  echo "aborting - unzip not installed and required"
  exit 1
fi
if curl -h 2&> /dev/null; then
  nettool="curl"
elif wget -h 2&> /dev/null; then
  nettool="wget"
else
  echo "aborting - neither wget nor curl installed and required"
  exit 1
fi

set +e

# try to get private IP
pri_ip=$(hostname -I 2> /dev/null | awk '{print $1}')
set -e

# download and extract binary
echo "Downloading and installing vault ${VAULT_VERSION}"
case "${nettool}" in
  wget)
    wget --no-check-certificate "${VAULT_URL}" --output-document="${VAULT_ZIP}"
    ;;
  curl)
    [ 200 -ne $(curl --write-out %{http_code} --silent --output ${VAULT_ZIP} ${VAULT_URL}) ] && exit 1
    ;;
esac

unzip "${VAULT_ZIP}"
sudo mv vault "$VAULT_DIR"
sudo chmod 0755 "${VAULT_PATH}"
sudo chown root:root "${VAULT_PATH}"


echo "Version Installed: $(vault --version)"
vault -autocomplete-install
complete -C "${VAULT_PATH}" vault
sudo setcap cap_ipc_lock=+ep "${VAULT_PATH}"


echo "Creating Vault user and directories"
sudo mkdir --parents "${VAULT_CONFIG_DIR}"
sudo useradd --system --home "${VAULT_CONFIG_DIR}" --shell /bin/false vault
sudo mkdir --parents "${VAULT_DATA_DIR}"
sudo chown --recursive vault:vault "${VAULT_DATA_DIR}"


echo "Creating vault config for ${VAULT_VERSION}"
sudo tee "${VAULT_CONFIG_DIR}/vault.hcl" > /dev/null <<VAULTCONFIG
ui = true
api_addr = ""
cluster_addr = ""
cluster_name="vault-enterprise"

listener "tcp" {
  address          = "0.0.0.0:8200"
  tls_disable      = "true"
}

# Integrated Storage Backend
storage "raft" {
  path    = "/opt/vault"
  node_id = "vault-1"
}
VAULTCONFIG

sudo sed -i "s|NODENAME|$NODE_NAME|g" "${VAULT_CONFIG_DIR}/vault.hcl"
[[ "$pri_ip" ]] && sudo sed -i "s|^api_addr.*|api_addr = \"http://$pri_ip:8200\"|g" "${VAULT_CONFIG_DIR}/vault.hcl"
[[ "$pri_ip" ]] && sudo sed -i "s|^cluster_addr.*|cluster_addr = \"https://$pri_ip:8201\"|g" "${VAULT_CONFIG_DIR}/vault.hcl"
[[ "$pri_ip" ]] && sudo sed -i "s|^#\ \ cluster_address.*|\ \ cluster_address  = \"$pri_ip:8201\"|g" "${VAULT_CONFIG_DIR}/vault.hcl"
sudo chown --recursive vault:vault "${VAULT_CONFIG_DIR}"
sudo chmod 640 "${VAULT_CONFIG_DIR}/vault.hcl"


echo "Creating vault systemd service"
sudo tee /etc/systemd/system/vault.service > /dev/null <<SYSDSERVICE
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=VAULTBINDIR/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
SYSDSERVICE

sudo sed -i "s|VAULTBINDIR|$VAULT_DIR|g" /etc/systemd/system/vault.service

echo 'export VAULT_LICENSE="02MV4UU43BK5HGYYTOJZWFQMTMNNEWU33JJVKGWM2OPJMXSTL2JF2E6R2RGFGUGMDYJVWU2MKMKRIXQTKXKF2FSMSZGRNGUYZQJVLU43CNKRTXQSLJO5UVSM2WPJSEOOLULJMEUZTBK5IWST3JJJWE26SSNFGUIULYJVUTC2CNKRBGQTCUNBVU26TDORHHUVJRLJBTAMCPK5DGWTTNKEZU42SVPFHVOWLJJRBUU4DCNZHDAWKXPBZVSWCSOBRDENLGMFLVC2KPNFEXCSLJO5UWCWCOPJSFOVTGMRDWY5C2KNETMSLKJF3U22SJORGUISLUJVCFEVKNNJCTMTLKMM3E2RDLOVHVISJUJZKGO6SOKRJGCSLJO5UWGM2SNBRW4UTGMRDWY5C2KNETMSLKJF3U22SJORGUISLUJVCFEVKNIRATMTKEIE3E2RCCMFEWS53JLJMGQ53BLBFGQZCHNR3GE3BZGBQVOMLMJFVG62KNNJAXSTLZGB3U22JQO5HEMULZJV5G6MKPKRXTCT2TGQ2U6VDMMFEWS53JMRDVM6LCK5WHKWKYKJYGEMRVMZSEO3DULJJUSNSJNJEXOTLKJV2E2RCJORGUIUSVJVVE2NSOKRVTMTSUNN2U6VDLGVLWSSLTJFXEE6LCGJJDCWJTKFUU62KKGJMVQVTTMRBUS42JNVNHGWKXMR5ES2TQG5EW2MLWLJEFM422LBGWST3MONUWEWCWONSEO23ULJDU25DDGJHGQYSHKVUUYQ2KNZRDGWTMMNWTK2DCNVHGYTCYIJ3GER3MNJSVGSLTJFWUM23ENVDHKWJSKZVUYV2SNBSEORLUMNEEU5TEI5LGUZCHNR3GE2KKMRTFQMB5FY4FCVJLJJLXCL2ENQ4HA32XHBSDQOKPIZCUI2SOM5VFUNKHME3WM2KGGJFDA2SINBJUO5BRKF3GIQSLLJHGQSCZJ5NDMSRSJVKEG2DGJZGXQNDCNNJCW43LMN2U66LTMN2TG4TNINYDCZCBNNRWCNDEKYYDGMZYKB3W2VTMMF3EUUBUOBFHQSKJHFCDMVKGJRKWCVSQNJVVOSTUMNCDM4DBNQ3G6T3GI5XEWMT2KBFUUUTNI5EFMM3FLJ3XCRTFFNXTO2ZPOMVUCVCONBIFUZ2TF5FVMWLHF5FSW3CHKB3UYN3KIJ4ESN2HJ5QWWNSVMFUWCSDPMVVTAUSUN43TERCRHU6Q"' >> ~/.bashrc

echo 'export VAULT_ADDR="http://127.0.0.1:8200"' >> ~/.bashrc

source ~/.bashrc

echo "Enable Vault systemd service"
sudo systemctl enable vault

echo 'export VAULT_ADDR="http://127.0.0.1:8200"' >> ~/.bashrc
