#!/usr/bin/env bash

# V2 paths: relative to formulas/eso/install/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

ESO_NAMESPACE=vkdr

startInfos() {
  boldInfo "ESO Install"
  bold "=============================="
  bold "=============================="
}

installESO() {
  debug "installESO: add/update helm repo"
  $VKDR_HELM repo add external-secrets https://charts.external-secrets.io
  $VKDR_HELM repo update external-secrets
  debug "installESO: installing External Secrets Operator"
  $VKDR_HELM upgrade --install external-secrets external-secrets/external-secrets \
    -n $ESO_NAMESPACE
}

runFormula() {
  startInfos
  createESONamespace
  installESO
}

createESONamespace() {
  debug "Create ESO namespace '$ESO_NAMESPACE'"
  echo "
apiVersion: v1
kind: Namespace
metadata:
  name: $ESO_NAMESPACE
" | $VKDR_KUBECTL apply -f -
}

runFormula
