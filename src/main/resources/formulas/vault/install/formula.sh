#!/usr/bin/env bash

VKDR_ENV_VAULT_DOMAIN=$1
VKDR_ENV_VAULT_SECURE=$2
VKDR_ENV_VAULT_DEV_MODE=$3
VKDR_ENV_VAULT_DEV_ROOT_TOKEN=$4
VKDR_ENV_VAULT_TLS_MODE=$5

# V2 paths: relative to formulas/vault/install/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"
source "$SHARED_DIR/lib/ingress-tools.sh"

VAULT_NAMESPACE=vkdr

startInfos() {
  boldInfo "Vault Install"
  bold "=============================="
  boldNotice "Domain: $VKDR_ENV_VAULT_DOMAIN"
  boldNotice "Secure: $VKDR_ENV_VAULT_SECURE"
  boldNotice "Dev Mode: $VKDR_ENV_VAULT_DEV_MODE"
  boldNotice "Dev Root Token: $VKDR_ENV_VAULT_DEV_ROOT_TOKEN"
  boldNotice "TLS Mode: $VKDR_ENV_VAULT_TLS_MODE"
  bold "=============================="
}

runFormula() {
  startInfos
  createNamespace
  settings
  configDomain
  setDevMode
  installVault
  postInstall
}

installVault() {
  debug "installVault: add/update helm repo"
  $VKDR_HELM repo add hashicorp https://helm.releases.hashicorp.com
  $VKDR_HELM repo update hashicorp
  debug "installVault: installing vault"
  $VKDR_HELM upgrade --install vault hashicorp/vault \
    -n $VAULT_NAMESPACE --values $VKDR_VAULT_VALUES
}

settings() {
  VKDR_VAULT_VALUES=/tmp/vault.yaml
  if [ "true" = "$VKDR_ENV_VAULT_TLS_MODE" ]; then
    debug "settings: setting vault tls mode in $VKDR_VAULT_VALUES"
    cp "$SHARED_DIR/values/vault-tls.yaml" $VKDR_VAULT_VALUES
  else
    debug "settings: setting vault non tls mode in $VKDR_VAULT_VALUES"
    cp "$SHARED_DIR/values/vault.yaml" $VKDR_VAULT_VALUES
  fi
}

configDomain() {
  if [ "$VKDR_ENV_VAULT_DOMAIN" != "localhost" ]; then
    debug "configDomain: setting vault domain to $VKDR_ENV_VAULT_DOMAIN in $VKDR_VAULT_VALUES"
    $VKDR_YQ -i ".server.ingress.hosts[0].host = \"vault.$VKDR_ENV_VAULT_DOMAIN\"" $VKDR_VAULT_VALUES
  fi
  if [ "true" = "$VKDR_ENV_VAULT_SECURE" ]; then
    debug "configDomain: setting ingress TLS domain in $VKDR_VAULT_VALUES"
    $VKDR_YQ -i ".server.ingress.tls[0].hosts[0] = \"vault.$VKDR_ENV_VAULT_DOMAIN\"" $VKDR_VAULT_VALUES
    addHostToACMEIngress "vault.$VKDR_ENV_VAULT_DOMAIN"
  else
    debug "configDomain: removing ingress TLS entry in $VKDR_VAULT_VALUES"
    $VKDR_YQ -i ".server.ingress.tls = []" $VKDR_VAULT_VALUES
  fi
}

setDevMode () {
  if [ "false" = "$VKDR_ENV_VAULT_DEV_MODE" ]; then return; fi
  debug "setDevMode: setting vault dev mode in $VKDR_VAULT_VALUES"
  $VKDR_YQ -i ".server.dev.enabled = true" $VKDR_VAULT_VALUES
  debug "setDevMode: setting vault dev root token in $VKDR_VAULT_VALUES"
  $VKDR_YQ -i ".server.dev.devRootToken = \"$VKDR_ENV_VAULT_DEV_ROOT_TOKEN\"" $VKDR_VAULT_VALUES
}

postInstall() {
  if [ "true" = "$VKDR_ENV_VAULT_DEV_MODE" ]; then
    debug "postInstall: saving dev mode root token in 'vault-keys' secret"
    $VKDR_KUBECTL create secret generic vault-keys -n $VAULT_NAMESPACE \
      --from-literal=root-token="$VKDR_ENV_VAULT_DEV_ROOT_TOKEN"
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
