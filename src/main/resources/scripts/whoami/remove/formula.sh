#!/usr/bin/env bash

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

WHOAMI_NAMESPACE=vkdr

startInfos() {
  boldInfo "Whoami Remove"
  bold "=============================="
}

runFormula() {
  startInfos
  removeWhoami
}

removeWhoami() {
  $VKDR_HELM delete whoami -n $WHOAMI_NAMESPACE
}

runFormula
