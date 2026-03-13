#!/usr/bin/env bash

FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

CROSSPLANE_NAMESPACE=crossplane-system

startInfos() {
  boldInfo "Crossplane Remove"
  bold "=============================="
}

runFormula() {
  startInfos
  removeCrossplane
}

removeCrossplane() {
  if $VKDR_HELM list -n $CROSSPLANE_NAMESPACE -q | grep -q "crossplane"; then
    $VKDR_HELM delete crossplane -n $CROSSPLANE_NAMESPACE
  fi
  $VKDR_KUBECTL delete namespace $CROSSPLANE_NAMESPACE --ignore-not-found
}

runFormula
