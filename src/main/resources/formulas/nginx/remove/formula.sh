#!/usr/bin/env bash

# V2 paths: relative to formulas/nginx/remove/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

startInfos() {
  boldInfo "Nginx Remove"
  bold "=============================="
}

runFormula() {
  startInfos
  removeNginx
}

removeNginx() {
  $VKDR_HELM delete ingress-nginx
}

runFormula
