#!/usr/bin/env bash

VKDR_ENV_GRAFANA_TOKEN=$1

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

GRAFANA_NAMESPACE=vkdr

startInfos() {
  boldInfo "Minio Install"
  bold "=============================="
  boldNotice "Grafana Cloud token: $VKDR_ENV_GRAFANA_TOKEN"
  bold "=============================="
}

runFormula() {
  startInfos
  settingMinio
  createNamespace
  installGrafana
}

settingMinio() {
  debug "settingKong: obtaining default Minio settings"
  VKDR_GRAFANA_VALUES=/tmp/grafana-cloud.yaml
  cp "$(dirname "$0")"/../../.util/values/grafana-cloud.yaml $VKDR_GRAFANA_VALUES
  $VKDR_YQ -i ".externalServices.prometheus.basicAuth.password = \"$VKDR_ENV_GRAFANA_TOKEN\"" $VKDR_GRAFANA_VALUES
  $VKDR_YQ -i ".externalServices.loki.basicAuth.password = \"$VKDR_ENV_GRAFANA_TOKEN\"" $VKDR_GRAFANA_VALUES
  $VKDR_YQ -i ".externalServices.tempo.basicAuth.password = \"$VKDR_ENV_GRAFANA_TOKEN\"" $VKDR_GRAFANA_VALUES
}

installGrafana() {
  #debug "installMinio: add/update helm repo"
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
