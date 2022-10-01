#!/usr/bin/env bash
# vault-install-linux.sh - Install Vault on Linux machines.
# From https://github.com/btkrausen/hashicorp/blob/master/vault/scripts/install_vault.sh

set -euxo pipefail

# Variables
VAULT_VERSION=1.11.2+ent
IP_ADDRESS=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
# Remove license information if using open source
VAULT_LICENSE=<ENTER LICENSE HERE>

# Create Prerequisites
echo "Creating System Prerequisites"

echo "Installing jq"
sudo yum install -y jq

echo "Installing unzip"
sudo yum install -y unzip

echo "Configuring system time"
sudo timedatectl set-timezone UTC

echo "Adding Vault system users"
create_ids() {
  sudo /usr/sbin/groupadd --force --system ${1}
  if ! getent passwd ${1} >/dev/null ; then
    sudo /usr/sbin/adduser \
      --system \
      --gid ${1} \
      --home /srv/${1} \
      --no-create-home \
      --comment "${1} account" \
      --shell /bin/false \
      ${1}  >/dev/null
  fi
}

create_ids vault

# Install Vault
# Update variables above to manage version, OSS/Ent, and platform
export VAULT_ARCHIVE="vault_${VAULT_VERSION}_linux_amd64.zip"
echo "Installing Vault Enterprise"
curl --silent -Lo /tmp/${VAULT_ARCHIVE} https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_ARCHIVE}
sudo unzip -d /usr/local/bin /tmp/${VAULT_ARCHIVE}

# Create and manage permissions on directories
echo "Configuring HashiCorp directories"
directory_setup() {
  sudo mkdir -pm 0750 /etc/${1}.d /var/lib/${1} /opt/${1}/data
  sudo mkdir -pm 0700 /etc/${1}.d/tls
  sudo chown -R ${2}:${2} /etc/${1}.d /opt/${1}/data
}

directory_setup vault vault

echo "Create systemd service file"

# Create Systemd file
echo '[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl

[Service]
User=vault
Group=vault

# Sandboxing settings to improve the security of the host by restricting vault privileges and access
ProtectSystem=true
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes

# Configure the capabilities of the vault process, particularly to lock memory.
# (support for multiple systemd versions)
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK

# Limit the number of file descriptors to the configured value and prevent memory being swapped to disk
LimitNOFILE=65536
LimitMEMLOCK=infinity

# Prevent vault and any child process from gaining new privileges
NoNewPrivileges=yes

ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitBurst=3

[Install]
WantedBy=multi-user.target' >> /etc/systemd/system/vault.service

sudo chmod 0664 /etc/systemd/system/vault.service
sudo systemctl daemon-reload

# Create Vault Configuration file
# Remove license reference information if using Vault OSS

echo "Creating Vault Configuration file"

cat <<-EOF > /etc/vault.d/vault.hcl
storage "raft" {
  path    = "/opt/vault/data"
  node_id = "<ENTER NODE NAME HERE>"
  performance_multiplier = 1
  retry_join {
    leader_api_addr = "https://<NODE_1_ADDRESS/NAME_HERE>:8200"
  }
  retry_join {
    leader_api_addr = "https://<NODE_2_ADDRESS/NAME_HERE>:8200"
  }
  retry_join {
    leader_api_addr = "https://<NODE_3_ADDRESS/NAME_HERE>:8200"
  }
  retry_join {
    leader_api_addr = "https://<NODE_4_ADDRESS/NAME_HERE>:8200"
  }
  retry_join {
    leader_api_addr = "https://<NODE_5_ADDRESS/NAME_HERE>:8200"
  }
}
listener "tcp" {
 address = "$IP_ADDRESS:8200"
 cluster_address = "$IP_ADDRESS:8201"
 tls_disable = 0
 tls_cert_file = "/etc/vault.d/tls/client.pem"
 tls_key_file = "/etc/vault.d/tls/cert.key"
}
api_addr = "https://vault.example.com:8200"
cluster_addr = "https://node-a.example.com:8201"
cluster_name = "vault-prod"
ui = true
log_level = "INFO"
license_path = "/etc/vault.d/vault.hclic"
EOF

# Create Vault License file
echo "Creating Vault License file"

echo $VAULT_LICENSE > /etc/vault.d/vault.hclic

# Cleanup
sudo rm /tmp/$VAULT_ARCHIVE