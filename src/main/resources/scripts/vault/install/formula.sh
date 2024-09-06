#!/usr/bin/env bash

VKDR_ENV_VAULT_DOMAIN=$1
VKDR_ENV_VAULT_SECURE=$2
VKDR_ENV_VAULT_DEV_MODE=$3
VKDR_ENV_VAULT_DEV_ROOT_TOKEN=$4

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"
source "$(dirname "$0")/../../.util/ingress-tools.sh"

VAULT_NAMESPACE=vkdr

startInfos() {
  boldInfo "Vault Install"
  bold "=============================="
  boldNotice "Domain: $VKDR_ENV_VAULT_DOMAIN"
  boldNotice "Secure: $VKDR_ENV_VAULT_SECURE"
  boldNotice "Dev Mode: $VKDR_ENV_VAULT_DEV_MODE"
  boldNotice "Dev Root Token: $VKDR_ENV_VAULT_DEV_ROOT_TOKEN"
  bold "=============================="
}

runFormula() {
  startInfos
  createNamespace
  settings
  configDomain
  setDevMode
  installVault
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
  cp "$(dirname "$0")/../../.util/values/vault.yaml" $VKDR_VAULT_VALUES
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
