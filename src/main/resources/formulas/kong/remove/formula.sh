#!/usr/bin/env bash

# V2 paths: relative to formulas/kong/remove/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

KONG_NAMESPACE=vkdr

startInfos() {
  boldInfo "Kong Remove"
  bold "=============================="
}

runFormula() {
  startInfos
  removeKong
}

removeKong() {
  $VKDR_HELM delete kong -n $KONG_NAMESPACE
}

runFormula
