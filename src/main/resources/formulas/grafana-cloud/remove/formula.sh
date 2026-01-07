#!/usr/bin/env bash

# V2 paths: relative to formulas/grafana-cloud/remove/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

GRAFANA_NAMESPACE=vkdr

startInfos() {
  boldInfo "Grafana Cloud Remove"
  bold "=============================="
}

runFormula() {
  startInfos
  removeGrafana
}

removeGrafana() {
  $VKDR_HELM delete grafana-cloud -n $GRAFANA_NAMESPACE
}

runFormula
