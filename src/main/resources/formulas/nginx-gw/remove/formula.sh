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
  # Wait for controller to clean up data plane pods before uninstalling
  debug "removeDefaultGateway: waiting for data plane pods to terminate"
  $VKDR_KUBECTL wait --for=delete pod -l gateway.networking.k8s.io/gateway-name=nginx -n nginx-gateway --timeout=60s 2>/dev/null || true
}

removeNginxProxy() {
  debug "removeNginxProxy: deleting NginxProxy resource"
  $VKDR_KUBECTL delete nginxproxy nginx-proxy-config -n nginx-gateway --ignore-not-found
}

removeNginxGatewayFabric() {
  debug "removeNginxGatewayFabric: uninstalling nginx-gateway"
  removeDefaultGateway
  removeNginxProxy
  $VKDR_HELM delete nginx-gateway -n nginx-gateway
}

runFormula() {
  startInfos
  removeNginxGatewayFabric
}

runFormula
