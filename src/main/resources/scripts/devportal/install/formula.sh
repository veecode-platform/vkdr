#!/usr/bin/env bash

VKDR_ENV_DEVPORTAL_DOMAIN=$1
VKDR_ENV_DEVPORTAL_SECURE=$2
VKDR_ENV_DEVPORTAL_GITHUB_TOKEN=$3
VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_ID=$4
VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_SECRET=$5
VKDR_ENV_DEVPORTAL_INSTALL_SAMPLES=$6
VKDR_ENV_DEVPORTAL_GRAFANA_TOKEN=$7

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"
source "$(dirname "$0")/../../.util/ingress-tools.sh"
source "$(dirname "$0")/../../.util/devportal-k8s-service-account/generateSAToken.sh"

VKDR_DEVPORTAL_VALUES="$(dirname "$0")/../../.util/values/devportal-common.yaml"
# port values override by detectClusterPorts
VKDR_HTTP_PORT=8000
VKDR_HTTPS_PORT=8001

startInfos() {
  boldInfo "DevPortal Install"
  bold "=============================="
  boldNotice "Domain: $VKDR_ENV_DEVPORTAL_DOMAIN"
  boldNotice "Secure: $VKDR_ENV_DEVPORTAL_SECURE"
  boldNotice "Github Token: *****${VKDR_ENV_DEVPORTAL_GITHUB_TOKEN: -3}"
  boldNotice "Github Client ID: *****${VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_ID: -3}"
  boldNotice "Github Client Secret: *****${VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_SECRET: -3}"
  boldNotice "Install Sample apps: $VKDR_ENV_DEVPORTAL_INSTALL_SAMPLES"
  boldNotice "Grafana Cloud token: *****${VKDR_ENV_DEVPORTAL_GRAFANA_TOKEN: -5}"
  bold "=============================="
  boldNotice "Cluster LB HTTP port: $VKDR_HTTP_PORT"
  boldNotice "Cluster LB HTTPS port: $VKDR_HTTPS_PORT"
  bold "=============================="
}

installDevPortal() {
  debug "installDevPortal: add/update helm repo"
  $VKDR_HELM repo add veecode-platform https://veecode-platform.github.io/public-charts/
  $VKDR_HELM repo update veecode-platform
  debug "installDevPortal: installing DevPortal (beta)"
  #VKDR_PROTOCOL=http
  #if [[ "$VKDR_ENV_DEVPORTAL_SECURE" == "true" ]]; then VKDR_PROTOCOL=https; fi
  VKDR_DEVPORTAL_PORT=""
    if [ "true" = "$VKDR_ENV_DEVPORTAL_SECURE" ]; then
      VKDR_PROTOCOL="https"
      if [ "$VKDR_HTTPS_PORT" != "443" ]; then
        VKDR_DEVPORTAL_PORT=":$VKDR_HTTPS_PORT"
      fi
    else
      VKDR_PROTOCOL="http"
      if [ "$VKDR_HTTP_PORT" != "80" ]; then
        VKDR_DEVPORTAL_PORT=":$VKDR_HTTP_PORT"
      fi
    fi
  local LOCATION_TARGET="https://github.com/veecode-platform/vkdr-catalog/blob/main/catalog-info.yaml"
  if [ "true" = "$VKDR_ENV_DEVPORTAL_INSTALL_SAMPLES" ]; then
    LOCATION_TARGET="https://github.com/veecode-platform/vkdr-catalog/blob/main/catalog-info-samples.yaml"
  fi
  debug "installDevPortal: DevPortal location target = $LOCATION_TARGET"
  $VKDR_HELM upgrade platform-devportal --install --wait --timeout 10m \
    veecode-platform/devportal --create-namespace -n platform \
    -f "$VKDR_DEVPORTAL_VALUES" \
    --set "ingress.host=devportal.${VKDR_ENV_DEVPORTAL_DOMAIN}" \
    --set "appConfig.app.baseUrl=${VKDR_PROTOCOL}://devportal.${VKDR_ENV_DEVPORTAL_DOMAIN}${VKDR_DEVPORTAL_PORT}" \
    --set "appConfig.backend.baseUrl=${VKDR_PROTOCOL}://devportal.${VKDR_ENV_DEVPORTAL_DOMAIN}${VKDR_DEVPORTAL_PORT}" \
    --set "integrations.github.token=${VKDR_ENV_DEVPORTAL_GITHUB_TOKEN}" \
    --set "auth.providers.github.clientId=${VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_ID}" \
    --set "auth.providers.github.clientSecret=${VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_SECRET}" \
    --set "kubernetes.clusterLocatorMethods[0].clusters[0].serviceAccountToken=${VKDR_SERVICE_ACCOUNT_TOKEN}" \
    --set "locations[0].target=${LOCATION_TARGET}"
}

checkForKong() {
  # check if kong is installed
  if $VKDR_HELM list -n vkdr | grep -q "^kong"; then
    debug "checkForKong: Kong already installed."
    return 0;
  fi
  debug "checkForKong: Kong not found, will install it as default ingress controller:"
  debug "checkForKong: running 'vkdr kong install --default-ic' -e -m standard"
  (
    vkdr kong install --default-ic -t "3.8" -e -m standard
  )
}

generateServiceAccountToken() {
  debug "generateServiceAccountToken: generating service account token"
  createDevPortalServiceAccount
  debug "generateServiceAccountToken: service account token = ${VKDR_SERVICE_ACCOUNT_TOKEN:0:10} (first 10 chars)"
}

installSampleApps() {
  if [ "true" != "$VKDR_ENV_DEVPORTAL_INSTALL_SAMPLES" ]; then
    debug "installSampleApps: skipping sample apps installation"
    return
  fi
  debug "installSampleApps: installing sample apps"
  local VKDR_SAMPLES_PATH="$(dirname "$0")/../../.util/sample-apps"
  $VKDR_KUBECTL apply -f "$VKDR_SAMPLES_PATH/petclinic.yaml" -n vkdr
  $VKDR_KUBECTL apply -f "$VKDR_SAMPLES_PATH/viacep-api.yaml" -n vkdr
}

runFormula() {
  detectClusterPorts
  startInfos
  checkForKong
  generateServiceAccountToken
  installDevPortal
  installSampleApps
}

runFormula
