#!/usr/bin/env bash

# V2 paths: relative to formulas/eso/remove/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

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
