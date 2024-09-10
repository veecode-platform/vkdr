#!/usr/bin/env bash

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

ESO_NAMESPACE=vkdr

startInfos() {
  boldInfo "ESO Remove"
  bold "=============================="
}

runFormula() {
  startInfos
  removeESO
}

removeESO() {
  $VKDR_HELM delete external-secrets -n $ESO_NAMESPACE
}

runFormula
