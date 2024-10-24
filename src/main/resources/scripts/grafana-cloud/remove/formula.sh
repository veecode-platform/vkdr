#!/usr/bin/env bash

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

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
