#!/usr/bin/env bash

# V2 paths: relative to formulas/devportal/remove/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

VKDR_NAMESPACE=platform

startInfos() {
  boldInfo "DevPortal Remove"
  bold "=============================="
}

runFormula() {
  startInfos
  remove
}

remove() {
  helm delete veecode-devportal -n $VKDR_NAMESPACE
}

runFormula
