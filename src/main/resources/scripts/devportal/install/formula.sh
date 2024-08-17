#!/usr/bin/env bash

VKDR_ENV_DEVPORTAL_DOMAIN=$1
VKDR_ENV_DEVPORTAL_SECURE=$2
VKDR_ENV_DEVPORTAL_GITHUB_TOKEN=$3
VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_ID=$4
VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_SECRET=$5

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"
source "$(dirname "$0")/../../.util/ingress-tools.sh"

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
  bold "=============================="
  boldNotice "Cluster LB HTTP port: $VKDR_HTTP_PORT"
  boldNotice "Cluster LB HTTPS port: $VKDR_HTTPS_PORT"
  bold "=============================="
}

installDevPortal() {
  debug "installDevPortal: add/update helm repo"
  helm repo add veecode-platform https://veecode-platform.github.io/public-charts/
  helm repo update veecode-platform
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
  helm upgrade platform-devportal --install --wait --timeout 10m \
    veecode-platform/devportal --create-namespace -n platform \
    -f "$VKDR_DEVPORTAL_VALUES" \
    --set "ingress.host=devportal.${VKDR_ENV_DEVPORTAL_DOMAIN}" \
    --set "appConfig.app.baseUrl=${VKDR_PROTOCOL}://devportal.${VKDR_ENV_DEVPORTAL_DOMAIN}${VKDR_DEVPORTAL_PORT}" \
    --set "appConfig.backend.baseUrl=${VKDR_PROTOCOL}://devportal.${VKDR_ENV_DEVPORTAL_DOMAIN}${VKDR_DEVPORTAL_PORT}" \
    --set "integrations.github.token=${VKDR_ENV_DEVPORTAL_GITHUB_TOKEN}" \
    --set "auth.providers.github.clientId=${VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_ID}" \
    --set "auth.providers.github.clientSecret=${VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_SECRET}"
}

runFormula() {
  detectClusterPorts
  startInfos
  installDevPortal
}

runFormula
