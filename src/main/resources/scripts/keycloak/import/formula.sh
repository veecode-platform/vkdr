#!/usr/bin/env bash

VKDR_ENV_KEYCLOAK_IMPORT_FILE=$1
VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD=$2

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

KEYCLOAK_NAMESPACE=vkdr
KEYCLOAK_POD_NAME=keycloak-0

startInfos() {
  boldInfo "Keycloak Import Realm"
  bold "=============================="
  boldNotice "File: $VKDR_ENV_KEYCLOAK_IMPORT_FILE"
  boldNotice "Admin password: $VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD"
  bold "=============================="
}

runFormula() {
  startInfos
  getSecret
  import
  postImport
}

getSecret() {
  if [ -z "$VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD" ]; then
    debug "getSecret: get admin password from k8s secret"
    VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD=$($VKDR_KUBECTL get secret keycloak -n "$KEYCLOAK_NAMESPACE" -o jsonpath="{.data.admin-password}" | base64 --decode)
  fi
}

import() {
  debug "import: Importing realm file $VKDR_ENV_KEYCLOAK_IMPORT_FILE"
  debug "import: keycloak config credentials"
  $VKDR_KUBECTL exec "$KEYCLOAK_POD_NAME" -n "$KEYCLOAK_NAMESPACE" -- sh -c "kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password $VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD --config /tmp/kcadm.config"
  debug "import: keycloak upload realm"
  $VKDR_KUBECTL cp "$VKDR_ENV_KEYCLOAK_IMPORT_FILE" "$KEYCLOAK_NAMESPACE/$KEYCLOAK_POD_NAME:/tmp/realm-import.json"
  debug "import: keycloak import realm"
  $VKDR_KUBECTL exec keycloak-0 -n "$KEYCLOAK_NAMESPACE" -- sh -c "kcadm.sh create realms --config /tmp/kcadm.config -f /tmp/realm-import.json"
}

postImport() {
  info "Keycloak import realm finished!"
}

runFormula
