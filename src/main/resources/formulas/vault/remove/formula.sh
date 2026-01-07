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
  $VKDR_HELM delete vault -n $VAULT_NAMESPACE
}

runFormula
