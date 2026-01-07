#!/usr/bin/env bash

# New v2 paths: relative to formulas/whoami/remove/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

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
