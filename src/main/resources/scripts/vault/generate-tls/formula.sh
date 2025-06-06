#!/usr/bin/env bash

VKDR_ENV_VAULT_COMMON_NAME=$1
VKDR_ENV_VAULT_VALIDITY_DAYS=$2
VKDR_ENV_VAULT_SAVE_TO_K8S=$3
VKDR_ENV_VAULT_FORCE=$4

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

VAULT_NAMESPACE=vkdr
CERT_DIR="$HOME/.vkdr/certs/vault"
CA_KEY="${CERT_DIR}/ca.key"
CA_CERT="${CERT_DIR}/ca.crt"
VAULT_KEY="${CERT_DIR}/vault.key"
VAULT_CSR="${CERT_DIR}/vault.csr"
VAULT_CERT="${CERT_DIR}/vault.crt"
VAULT_CONFIG="${CERT_DIR}/vault-csr.conf"

startInfos() {
  boldInfo "Vault Generate TLS Certificates"
  bold "=============================="
  boldNotice "Common Name: $VKDR_ENV_VAULT_COMMON_NAME"
  boldNotice "Validity Days: $VKDR_ENV_VAULT_VALIDITY_DAYS"
  boldNotice "Save to K8s: $VKDR_ENV_VAULT_SAVE_TO_K8S"
  boldNotice "Force: $VKDR_ENV_VAULT_FORCE"
  bold "=============================="
}

runFormula() {
  startInfos
  createNamespace
  createCertDir
  generateCA
  generateVaultCert
  if [ "$VKDR_ENV_VAULT_SAVE_TO_K8S" = "true" ]; then
    createK8sSecrets
    info "TLS certificates generated and saved to Kubernetes secrets"
  else
    info "TLS certificates generated successfully in $CERT_DIR"
  fi
  info "To use these certificates, install Vault with TLS mode enabled:"
  info "vkdr vault install --tls"
}

createCertDir() {
  debug "Creating certificate directory: $CERT_DIR"
  mkdir -p "$CERT_DIR"
}

generateCA() {
  if [ -f "$CA_CERT" ] && [ "$VKDR_ENV_VAULT_FORCE" != "true" ]; then
    info "CA certificate already exists, skipping CA generation"
    return
  elif [ -f "$CA_CERT" ] && [ "$VKDR_ENV_VAULT_FORCE" = "true" ]; then
    info "Force flag set, regenerating CA certificate"
    rm -f "$CA_KEY" "$CA_CERT"
  else
    info "Generating CA certificate"
  fi
  
  debug "Creating CA private key"
  openssl genrsa -out "$CA_KEY" 2048
  
  debug "Creating CA certificate"
  openssl req -x509 -new -nodes -key "$CA_KEY" -sha256 -days "$VKDR_ENV_VAULT_VALIDITY_DAYS" \
    -out "$CA_CERT" -subj "/CN=Vault CA/O=VKDR/C=BR"
}

generateVaultCert() {
  if [ -f "$VAULT_CERT" ] && [ -f "$VAULT_KEY" ] && [ "$VKDR_ENV_VAULT_FORCE" != "true" ]; then
    info "Vault certificate and key already exist, skipping Vault certificate generation"
    return
  elif [ -f "$VAULT_CERT" ] && [ -f "$VAULT_KEY" ] && [ "$VKDR_ENV_VAULT_FORCE" = "true" ]; then
    info "Force flag set, regenerating Vault certificate"
    rm -f "$VAULT_KEY" "$VAULT_CERT" "$VAULT_CSR"
  else
    info "Generating Vault certificate"
  fi
  
  # Create CSR config
  debug "Creating CSR configuration"
  cat > "$VAULT_CONFIG" <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[dn]
CN = ${VKDR_ENV_VAULT_COMMON_NAME}
O = VKDR
C = BR

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${VKDR_ENV_VAULT_COMMON_NAME}
DNS.2 = vault
DNS.3 = vault.${VAULT_NAMESPACE}
DNS.4 = vault.${VAULT_NAMESPACE}.svc
DNS.5 = vault.${VAULT_NAMESPACE}.svc.cluster.local
DNS.6 = localhost
IP.1 = 127.0.0.1
EOF

  # Generate private key
  debug "Generating private key"
  openssl genrsa -out "$VAULT_KEY" 2048
  
  # Generate CSR
  debug "Generating CSR"
  openssl req -new -key "$VAULT_KEY" -out "$VAULT_CSR" -config "$VAULT_CONFIG"
  
  # Generate certificate
  debug "Generating certificate"
  openssl x509 -req -in "$VAULT_CSR" -CA "$CA_CERT" -CAkey "$CA_KEY" \
    -CAcreateserial -out "$VAULT_CERT" -days "$VKDR_ENV_VAULT_VALIDITY_DAYS" \
    -extensions req_ext -extfile "$VAULT_CONFIG"
}

createK8sSecrets() {
  info "Creating Kubernetes secrets for Vault TLS"
  
  # Create CA secret
  debug "Creating CA secret"
  if [ "$VKDR_ENV_VAULT_FORCE" = "true" ]; then
    debug "Force flag set, replacing existing CA secret if it exists"
    $VKDR_KUBECTL create secret generic vault-server-ca \
      --namespace="$VAULT_NAMESPACE" \
      --from-file=ca.crt="$CA_CERT" \
      --dry-run=client -o yaml | $VKDR_KUBECTL apply -f -
  else
    $VKDR_KUBECTL create secret generic vault-server-ca \
      --namespace="$VAULT_NAMESPACE" \
      --from-file=ca.crt="$CA_CERT"
  fi
  
  # Create server TLS secret
  debug "Creating server TLS secret"
  if [ "$VKDR_ENV_VAULT_FORCE" = "true" ]; then
    debug "Force flag set, replacing existing server TLS secret if it exists"
    $VKDR_KUBECTL create secret tls vault-server-tls \
      --namespace="$VAULT_NAMESPACE" \
      --key="$VAULT_KEY" \
      --cert="$VAULT_CERT" \
      --dry-run=client -o yaml | $VKDR_KUBECTL apply -f -
  else
    $VKDR_KUBECTL create secret tls vault-server-tls \
      --namespace="$VAULT_NAMESPACE" \
      --key="$VAULT_KEY" \
      --cert="$VAULT_CERT"
  fi
}

createNamespace() {
  debug "Create namespace '$VAULT_NAMESPACE'"
  echo "
apiVersion: v1
kind: Namespace
metadata:
  name: $VAULT_NAMESPACE
" | $VKDR_KUBECTL apply -f -
}

runFormula
