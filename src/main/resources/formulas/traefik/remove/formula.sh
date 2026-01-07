#!/usr/bin/env bash

# V2 paths: relative to formulas/traefik/remove/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

startInfos() {
  boldInfo "Traefik Remove"
  bold "=============================="
  bold "=============================="
}

removeTraefik() {
  debug "removeTraefik: uninstalling traefik"
  $VKDR_HELM uninstall traefik
}

runFormula() {
  startInfos
  removeTraefik
}

runFormula
