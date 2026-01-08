#!/usr/bin/env bash

VKDR_ENV_DELETE_OPERATOR=$1

# V2 paths: relative to formulas/kong-gw/remove/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

startInfos() {
  boldInfo "Kong Gateway Remove"
  bold "=============================="
  if [ "$VKDR_ENV_DELETE_OPERATOR" = "true" ]; then
    boldNotice "Mode: Full removal (Gateway + Operator + TLS Secret)"
  else
    boldNotice "Mode: Gateway only (Operator preserved)"
  fi
  bold "=============================="
}

removeGateway() {
  debug "removeGateway: deleting Gateway resource"
  $VKDR_KUBECTL delete gateway kong -n kong-system --ignore-not-found
  # Wait for controller to clean up data plane pods
  debug "removeGateway: waiting for data plane pods to terminate"
  $VKDR_KUBECTL wait --for=delete pod -l app=dataplane-kong -n kong-system --timeout=60s 2>/dev/null || true
}

removeGatewayConfiguration() {
  debug "removeGatewayConfiguration: deleting GatewayConfiguration resource"
  $VKDR_KUBECTL delete gatewayconfiguration kong-config -n kong-system --ignore-not-found
}

removeGatewayClass() {
  debug "removeGatewayClass: deleting GatewayClass"
  $VKDR_KUBECTL delete gatewayclass kong --ignore-not-found
}

removeOperator() {
  debug "removeOperator: uninstalling kong-operator helm release"
  if $VKDR_HELM list -n kong-system -q 2>/dev/null | grep -q "kong-operator"; then
    $VKDR_HELM delete kong-operator -n kong-system
  else
    debug "removeOperator: helm release not found, skipping"
  fi
}

removeNamespace() {
  debug "removeNamespace: deleting kong-system namespace"
  $VKDR_KUBECTL delete namespace kong-system --ignore-not-found
}

runFormula() {
  startInfos
  removeGateway
  removeGatewayConfiguration
  if [ "$VKDR_ENV_DELETE_OPERATOR" = "true" ]; then
    removeGatewayClass
    removeOperator
    removeNamespace
  fi
}

runFormula
