#!/bin/bash
set -e

# Update system
yum update -y

# Install required packages
yum install -y unzip jq awscli

# Download and install Vault
VAULT_VERSION="1.15.2"
cd /tmp
curl -LO "https://releases.hashicorp.com/vault/$VAULT_VERSION/vault_$${VAULT_VERSION}_linux_amd64.zip"
unzip vault_$${VAULT_VERSION}_linux_amd64.zip
sudo mv vault /usr/local/bin/
sudo chmod +x /usr/local/bin/vault

# Create vault user
sudo useradd --system --home /etc/vault.d --shell /bin/false vault

# Create directories
sudo mkdir -p /etc/vault.d
sudo mkdir -p /opt/vault/data
sudo mkdir -p /opt/vault/logs

# Set ownership
sudo chown -R vault:vault /etc/vault.d
sudo chown -R vault:vault /opt/vault

# Create Vault configuration
cat << EOF | sudo tee /etc/vault.d/vault.hcl
ui = true
disable_mlock = true

storage "file" {
  path = "/opt/vault/data"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = 1
}

seal "awskms" {
  region     = "$(curl -s http://169.254.169.254/latest/meta-data/placement/region)"
  kms_key_id = "${kms_key_id}"
}

api_addr = "http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):8200"
cluster_addr = "http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):8201"

log_level = "INFO"
log_file = "/opt/vault/logs/vault.log"
EOF

# Set permissions on config file
sudo chown vault:vault /etc/vault.d/vault.hcl
sudo chmod 640 /etc/vault.d/vault.hcl

# Create systemd service
cat << 'EOF' | sudo tee /etc/systemd/system/vault.service
[Unit]
Description=HashiCorp Vault
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
Type=notify
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
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Vault
sudo systemctl daemon-reload
sudo systemctl enable vault
sudo systemctl start vault

# Wait for Vault to start
sleep 10

# Create backup script
cat << EOF | sudo tee /usr/local/bin/vault-backup.sh
#!/bin/bash
set -e

BACKUP_DIR="/tmp/vault-backup"
BACKUP_FILE="vault-backup-\$(date +%Y%m%d-%H%M%S).tar.gz"
S3_BUCKET="${backup_bucket_name}"

# Create backup directory
mkdir -p \$BACKUP_DIR

# Backup Vault data
sudo cp -r /opt/vault/data \$BACKUP_DIR/
sudo cp /etc/vault.d/vault.hcl \$BACKUP_DIR/

# Create tarball
tar -czf /tmp/\$BACKUP_FILE -C \$BACKUP_DIR .

# Upload to S3
aws s3 cp /tmp/\$BACKUP_FILE s3://\$S3_BUCKET/vault-backups/

# Cleanup
rm -rf \$BACKUP_DIR
rm -f /tmp/\$BACKUP_FILE

echo "Vault backup completed: \$BACKUP_FILE"
EOF

sudo chmod +x /usr/local/bin/vault-backup.sh

# Create daily backup cron job
echo "0 2 * * * /usr/local/bin/vault-backup.sh" | sudo crontab -u vault -

# Create Vault initialization script
cat << 'EOF' | sudo tee /usr/local/bin/init-vault.sh
#!/bin/bash

export VAULT_ADDR="http://127.0.0.1:8200"

echo "Checking Vault status..."
vault status

if vault status | grep -q "Initialized.*false"; then
    echo "Initializing Vault..."
    vault operator init -key-shares=3 -key-threshold=2 > /tmp/vault-init.txt
    echo "Vault initialized! Keys saved to /tmp/vault-init.txt"
    echo "IMPORTANT: Save these keys securely!"
else
    echo "Vault is already initialized"
fi
EOF

sudo chmod +x /usr/local/bin/init-vault.sh

# Set environment variable for Vault CLI
echo 'export VAULT_ADDR="http://127.0.0.1:8200"' | sudo tee /etc/profile.d/vault.sh

# Signal completion
/opt/aws/bin/cfn-signal --exit-code $? --stack ${project_name}-${environment} --resource VaultInstance --region $(curl -s http://169.254.169.254/latest/meta-data/placement/region) || true

echo "Vault installation completed successfully!"
echo "To initialize Vault, run: sudo /usr/local/bin/init-vault.sh"
