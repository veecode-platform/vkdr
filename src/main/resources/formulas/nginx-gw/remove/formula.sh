#!/usr/bin/env bash

VKDR_ENV_DELETE_FABRIC=$1

# V2 paths: relative to formulas/nginx-gw/remove/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

startInfos() {
  boldInfo "NGINX Gateway Remove"
  bold "=============================="
  if [ "$VKDR_ENV_DELETE_FABRIC" = "true" ]; then
    boldNotice "Mode: Full removal (Gateway + Control Plane + TLS Secret)"
  else
    boldNotice "Mode: Gateway only (Control Plane preserved)"
  fi
  bold "=============================="
}

removeGateway() {
  debug "removeGateway: deleting Gateway resource"
  $VKDR_KUBECTL delete gateway nginx -n nginx-gateway --ignore-not-found
  # Wait for controller to clean up data plane pods
  debug "removeGateway: waiting for data plane pods to terminate"
  $VKDR_KUBECTL wait --for=delete pod -l gateway.networking.k8s.io/gateway-name=nginx -n nginx-gateway --timeout=60s 2>/dev/null || true
}

removeNginxProxy() {
  debug "removeNginxProxy: deleting NginxProxy resource"
  $VKDR_KUBECTL delete nginxproxy nginx-proxy-config -n nginx-gateway --ignore-not-found
}

removeControlPlane() {
  debug "removeControlPlane: uninstalling nginx-gateway helm release"
  if $VKDR_HELM list -n nginx-gateway -q 2>/dev/null | grep -q "nginx-gateway"; then
    $VKDR_HELM delete nginx-gateway -n nginx-gateway
  else
    debug "removeControlPlane: helm release not found, skipping"
  fi
}

removeNamespace() {
  debug "removeNamespace: deleting nginx-gateway namespace"
  $VKDR_KUBECTL delete namespace nginx-gateway --ignore-not-found
}

runFormula() {
  startInfos
  removeGateway
  removeNginxProxy
  if [ "$VKDR_ENV_DELETE_FABRIC" = "true" ]; then
    removeControlPlane
    removeNamespace
  fi
}

runFormula
