#!/usr/bin/env bash

VKDR_ENV_KEYCLOAK_DOMAIN=$1
VKDR_ENV_KEYCLOAK_SECURE=$2
VKDR_ENV_KEYCLOAK_ADMIN_USER=$3
VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD=$4

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

KEYCLOAK_NAMESPACE=vkdr

startInfos() {
  boldInfo "Keycloak Install"
  bold "=============================="
  boldNotice "Domain: $VKDR_ENV_KEYCLOAK_DOMAIN"
  boldNotice "Secure: $VKDR_ENV_KEYCLOAK_SECURE"
  boldNotice "Admin User: $VKDR_ENV_KEYCLOAK_ADMIN_USER"
  boldNotice "Admin Password: $VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD"
  bold "=============================="
}

runFormula() {
  startInfos
  configure
  configDomain
  createNamespace
  install
  postInstall
}

configure() {
  VKDR_KEYCLOAK_VALUES=/tmp/keycloak-standard.yaml
  cp "$(dirname "$0")"/../../.util/values/keycloak-standard.yaml $VKDR_KEYCLOAK_VALUES
  # set domain to "auth.DOMAIN"

  # if there is a "keycloak-pg-secret" use those credentials and do not install postgres subchart
  if $VKDR_KUBECTL get secrets -n $KEYCLOAK_NAMESPACE | grep -q "keycloak-pg-secret" ; then
    VKDR_KEYCLOAK_SECRET_VALUES="$(dirname "$0")"/../../.util/values/delta-keycloak-std-dbsecrets.yaml
    YAML_TMP_FILE_SECRET=/tmp/keycloak-secret-std.yaml
    $VKDR_YQ eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' $VKDR_KEYCLOAK_VALUES $VKDR_KEYCLOAK_SECRET_VALUES > $YAML_TMP_FILE_SECRET
    VKDR_KEYCLOAK_VALUES=$YAML_TMP_FILE_SECRET
  fi
}

configDomain() {
  if [ "$VKDR_ENV_KONG_DOMAIN" != "localhost" ]; then
    debug "configDomain: setting keycloak hostname to 'auth.$VKDR_ENV_KEYCLOAK_DOMAIN' in $VKDR_KEYCLOAK_VALUES"
    $VKDR_YQ eval ".ingress.hostname = \"auth.$VKDR_ENV_KEYCLOAK_DOMAIN\"" -i $VKDR_KEYCLOAK_VALUES
  fi
}

install() {
  debug "Keycloak install: add/update helm repo"
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo update
  debug "install: installing Keycloak"
  helm upgrade -i keycloak bitnami/keycloak \
    -n $KEYCLOAK_NAMESPACE --version 21.2.1 --values $VKDR_KEYCLOAK_VALUES
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
