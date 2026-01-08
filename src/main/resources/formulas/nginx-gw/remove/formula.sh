#!/usr/bin/env bash

# V2 paths: relative to formulas/nginx-gw/remove/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

startInfos() {
  boldInfo "NGINX Gateway Fabric Remove"
  bold "=============================="
}

removeDefaultGateway() {
  debug "removeDefaultGateway: deleting default Gateway resource"
  $VKDR_KUBECTL delete gateway nginx -n nginx-gateway --ignore-not-found
}

removeNginxGatewayFabric() {
  debug "removeNginxGatewayFabric: uninstalling nginx-gateway"
  removeDefaultGateway
  $VKDR_HELM delete nginx-gateway -n nginx-gateway
}

runFormula() {
  startInfos
  removeNginxGatewayFabric
}

runFormula
