#!/usr/bin/env bash

VKDR_ENV_WHOAMI_DOMAIN=$1
VKDR_ENV_WHOAMI_SECURE=$2

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"
source "$(dirname "$0")/../../.util/ingress-tools.sh"

WHOAMI_NAMESPACE=vkdr

startInfos() {
  boldInfo "Whoami Install"
  bold "=============================="
  boldNotice "Domain: $VKDR_ENV_WHOAMI_DOMAIN"
  boldNotice "Secure: $VKDR_ENV_WHOAMI_SECURE"
  bold "=============================="
}

runFormula() {
  startInfos
  createNamespace
  configValues
  configDomain
  install
  postInstall
}

configValues() {
  VKDR_TMP_VALUES=/tmp/whoami.yaml
  cp "$(dirname "$0")"/../../.util/values/whoami.yaml $VKDR_TMP_VALUES
}

configDomain() {
  # change domain
  if [ "$VKDR_ENV_WHOAMI_DOMAIN" != "localhost" ]; then
    debug "configDomain: setting ingress domain to $VKDR_ENV_WHOAMI_DOMAIN in $VKDR_TMP_VALUES"
    $VKDR_YQ -i ".ingress.hosts[0].host = \"whoami.$VKDR_ENV_WHOAMI_DOMAIN\"" $VKDR_TMP_VALUES
  fi
  if [ "true" = "$VKDR_ENV_WHOAMI_SECURE" ]; then
    debug "configDomain: setting ingress TLS domain in $VKDR_TMP_VALUES"
    $VKDR_YQ -i ".ingress.tls[0].hosts[0] = \"whoami.$VKDR_ENV_WHOAMI_DOMAIN\"" $VKDR_TMP_VALUES
    addHostToACMEIngress "whoami.$VKDR_ENV_WHOAMI_DOMAIN"
  else
    debug "configDomain: removing ingress TLS entry in $VKDR_TMP_VALUES"
    $VKDR_YQ -i ".ingress.tls = []" $VKDR_TMP_VALUES
  fi
}


install() {
  debug "install: add/update helm repo"
  $VKDR_HELM repo add cowboysysop https://cowboysysop.github.io/charts/
  $VKDR_HELM repo update
  debug "install: installing whoami"
  $VKDR_HELM upgrade -i whoami cowboysysop/whoami -n $WHOAMI_NAMESPACE --values $VKDR_TMP_VALUES
}

postInstall() {
  info "Whoami install finished!"
}

createNamespace() {
  debug "Create namespace '$WHOAMI_NAMESPACE'"
  echo "
apiVersion: v1
kind: Namespace
metadata:
  name: $WHOAMI_NAMESPACE
" | $VKDR_KUBECTL apply -f -
}

runFormula
