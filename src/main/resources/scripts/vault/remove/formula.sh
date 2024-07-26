#!/usr/bin/env bash

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

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
