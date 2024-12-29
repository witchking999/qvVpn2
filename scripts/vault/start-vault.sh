#!/bin/bash
# Script to set up Vault configuration, generate self-signed certificates, and start Vault in full mode

set -e

VAULT_BIN="/usr/local/bin/vault"
VAULT_CONFIG_FILE="/tmp/vault-server.hcl"
VAULT_DATA_DIR="/tmp/vault-data"
VAULT_CERT_FILE="/tmp/vault-cert.pem"
VAULT_KEY_FILE="/tmp/vault-key.pem"
VAULT_LOG_FILE="/tmp/vault.log"

# Ensure Vault binary exists
if [[ ! -f "$VAULT_BIN" ]]; then
  echo "Error: Vault binary not found at $VAULT_BIN. Please install Vault first."
  exit 1
fi

# Step 1: Create directory for Vault data
echo "Creating Vault data directory at $VAULT_DATA_DIR..."
mkdir -p "$VAULT_DATA_DIR"

# Step 2: Generate self-signed TLS certificate
echo "Generating self-signed TLS certificate..."
openssl req -x509 -newkey rsa:4096 -sha256 -days 365 \
  -nodes -keyout "$VAULT_KEY_FILE" -out "$VAULT_CERT_FILE" \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

echo "TLS certificate and key generated at $VAULT_CERT_FILE and $VAULT_KEY_FILE."

# Step 3: Create Vault configuration file
echo "Creating Vault configuration file at $VAULT_CONFIG_FILE..."
cat > "$VAULT_CONFIG_FILE" << EOF
api_addr                = "https://127.0.0.1:8200"
cluster_addr            = "https://127.0.0.1:8201"
cluster_name            = "qVvpn-cluster"
disable_mlock           = true
ui                      = true

listener "tcp" {
  address       = "127.0.0.1:8200"
  tls_cert_file = "$VAULT_CERT_FILE"
  tls_key_file  = "$VAULT_KEY_FILE"
}

backend "raft" {
  path    = "$VAULT_DATA_DIR"
  node_id = "qv-vault-node"
}
EOF

echo "Vault configuration file created."

# Step 4: Start Vault server
echo "Starting Vault server with configuration: $VAULT_CONFIG_FILE..."
$VAULT_BIN server -config="$VAULT_CONFIG_FILE" > "$VAULT_LOG_FILE" 2>&1 &

# Wait for Vault to start
sleep 5

# Step 5: Extract Root Token from Logs
VAULT_ROOT_TOKEN=$(grep 'Root Token:' "$VAULT_LOG_FILE" | awk '{print $NF}')

if [[ -z "$VAULT_ROOT_TOKEN" ]]; then
  echo "Error: Failed to extract root token from logs."
  exit 1
fi

# Export Root Token
export VAULT_TOKEN="$VAULT_ROOT_TOKEN"
echo "Vault root token extracted and exported: $VAULT_ROOT_TOKEN"

# Step 6: Verify Vault Status
echo "Verifying Vault status..."
curl --silent --header "X-Vault-Token: $VAULT_TOKEN" \
  "$VAULT_ADDR/v1/sys/health" | jq

echo "Vault setup and startup completed successfully."
