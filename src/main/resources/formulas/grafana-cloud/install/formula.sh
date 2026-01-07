#!/usr/bin/env bash

VKDR_ENV_GRAFANA_TOKEN=$1

# V2 paths: relative to formulas/grafana-cloud/install/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

GRAFANA_NAMESPACE=vkdr

startInfos() {
  boldInfo "Grafana Cloud Install"
  bold "=============================="
  boldNotice "Grafana Cloud token: $VKDR_ENV_GRAFANA_TOKEN"
  bold "=============================="
}

runFormula() {
  startInfos
  settingGrafana
  createNamespace
  installGrafana
}

settingGrafana() {
  debug "settingGrafana: obtaining default Grafana Cloud settings"
  VKDR_GRAFANA_VALUES=/tmp/grafana-cloud.yaml
  cp "$SHARED_DIR/values/grafana-cloud.yaml" $VKDR_GRAFANA_VALUES
  $VKDR_YQ -i ".externalServices.prometheus.basicAuth.password = \"$VKDR_ENV_GRAFANA_TOKEN\"" $VKDR_GRAFANA_VALUES
  $VKDR_YQ -i ".externalServices.loki.basicAuth.password = \"$VKDR_ENV_GRAFANA_TOKEN\"" $VKDR_GRAFANA_VALUES
  $VKDR_YQ -i ".externalServices.tempo.basicAuth.password = \"$VKDR_ENV_GRAFANA_TOKEN\"" $VKDR_GRAFANA_VALUES
}

installGrafana() {
  #debug "installGrafana: add/update helm repo"
  $VKDR_HELM repo add grafana https://grafana.github.io/helm-charts
  $VKDR_HELM repo update grafana
  debug "installGrafana: installing Grafana Cloud"
  $VKDR_HELM upgrade -i grafana-cloud grafana/k8s-monitoring -n $GRAFANA_NAMESPACE --values $VKDR_GRAFANA_VALUES
}

createNamespace() {
  debug "Create Grafana namespace '$GRAFANA_NAMESPACE'"
  echo "
apiVersion: v1
kind: Namespace
metadata:
  name: $GRAFANA_NAMESPACE
" | $VKDR_KUBECTL apply -f -
}

runFormula
