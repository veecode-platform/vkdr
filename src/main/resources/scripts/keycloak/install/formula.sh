#!/usr/bin/env bash

VKDR_ENV_KEYCLOAK_DOMAIN=$1
VKDR_ENV_KEYCLOAK_SECURE=$2

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

KEYCLOAK_NAMESPACE=vkdr

startInfos() {
  boldInfo "Keycloak Install"
  bold "=============================="
  boldNotice "Domain: $VKDR_ENV_KEYCLOAK_DOMAIN"
  boldNotice "Secure: $VKDR_ENV_KEYCLOAK_SECURE"
  bold "=============================="
}

runFormula() {
  startInfos
  createNamespace
  install
  postInstall
}


install() {
  debug "Keycloak install: add/update helm repo"
  helm repo add kong https://charts.konghq.com
  helm repo update
  error "Keycloak install: not implemented yet"
  exit 1
  #debug "install: installing Keycloak"
  #helm upgrade -i kong kong/kong -n $KONG_NAMESPACE --values $VKDR_KONG_VALUES
}

postInstall() {
  info "Keycloak install finished!"
}

createNamespace() {
  echo "
apiVersion: v1
kind: Namespace
metadata:
  name: $KEYCLOAK_NAMESPACE
" | kubectl apply -f -
}

runFormula
