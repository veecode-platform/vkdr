#!/usr/bin/env bash

# V2 paths: relative to formulas/vault/remove/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

VAULT_NAMESPACE=vkdr

startInfos() {
  boldInfo "Vault Remove"
  bold "=============================="
}

runFormula() {
  startInfos
  removeVault
}

removeVault() {
  if $VKDR_HELM list -n $VAULT_NAMESPACE -q | grep -q "^vault$"; then
    $VKDR_HELM delete vault -n $VAULT_NAMESPACE
  else
    debug "removeVault: helm release not found, skipping"
  fi
  # Clean up secrets
  $VKDR_KUBECTL delete secret vault-keys -n $VAULT_NAMESPACE --ignore-not-found
  $VKDR_KUBECTL delete secret vault-server-ca -n $VAULT_NAMESPACE --ignore-not-found
  $VKDR_KUBECTL delete secret vault-server-tls -n $VAULT_NAMESPACE --ignore-not-found
}

runFormula
