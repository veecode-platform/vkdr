#!/usr/bin/env bash

VKDR_ENV_KEYCLOAK_EXPORT_FILE=$1
VKDR_ENV_KEYCLOAK_REALM=$2
VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD=$3

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

KEYCLOAK_NAMESPACE=vkdr
KEYCLOAK_POD_NAME=keycloak-0

startInfos() {
  boldInfo "Keycloak Export Realm"
  bold "=============================="
  boldNotice "File: $VKDR_ENV_KEYCLOAK_EXPORT_FILE"
  boldNotice "Realm: $VKDR_ENV_KEYCLOAK_REALM"
  boldNotice "Admin password: ${VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD:-(will read from secret)}"
  bold "=============================="
}

runFormula() {
  startInfos
  getSecret
  export
  postExport
}

getSecret() {
  if [ -z "$VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD" ]; then
    debug "getSecret: get admin password from k8s secret"
    VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD=$($VKDR_KUBECTL get secret keycloak -n "$KEYCLOAK_NAMESPACE" -o jsonpath="{.data.admin-password}" | base64 --decode)
  fi
}

export() {
  debug "export: Exporting realm '$VKDR_ENV_KEYCLOAK_REALM'"
  RAND_SUFIX=$(head -c 32 /dev/urandom | LC_CTYPE=C tr -dc 'a-zA-Z0-9' | head -c 4)
  KCADM_CONFIG=/tmp/kcadm-$RAND_SUFIX.config
  REALM_FILE=/tmp/realm-export-$RAND_SUFIX.json
  USERS_FILE=/tmp/users-export-$RAND_SUFIX.json
  GROUPS_FILE=/tmp/groups-export-$RAND_SUFIX.json
  CLIENTS_FILE=/tmp/clients-export-$RAND_SUFIX.json
  debug "export: keycloak config credentials into $KCADM_CONFIG"
  $VKDR_KUBECTL exec "$KEYCLOAK_POD_NAME" -c keycloak -n "$KEYCLOAK_NAMESPACE" -- sh -c "kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password $VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD --config $KCADM_CONFIG"
  debug "export: keycloak export realm into $REALM_FILE"
  $VKDR_KUBECTL exec keycloak-0 -c keycloak -n "$KEYCLOAK_NAMESPACE" -- sh -c "kcadm.sh get realms/$VKDR_ENV_KEYCLOAK_REALM --config $KCADM_CONFIG" > $REALM_FILE
  debug "export: keycloak export users into $USERS_FILE"
  $VKDR_KUBECTL exec keycloak-0 -c keycloak -n "$KEYCLOAK_NAMESPACE" -- sh -c "kcadm.sh get users -r $VKDR_ENV_KEYCLOAK_REALM --config $KCADM_CONFIG" > $USERS_FILE
  debug "export: keycloak export groups into $GROUPS_FILE"
  $VKDR_KUBECTL exec keycloak-0 -c keycloak -n "$KEYCLOAK_NAMESPACE" -- sh -c "kcadm.sh get groups -r $VKDR_ENV_KEYCLOAK_REALM --config $KCADM_CONFIG" > $GROUPS_FILE
  debug "export: keycloak export clients into $CLIENTS_FILE"
  $VKDR_KUBECTL exec keycloak-0 -c keycloak -n "$KEYCLOAK_NAMESPACE" -- sh -c "kcadm.sh get clients -r $VKDR_ENV_KEYCLOAK_REALM --config $KCADM_CONFIG" > $CLIENTS_FILE
  debug "export: Merging all data into realm file $VKDR_ENV_KEYCLOAK_EXPORT_FILE"
  jq --argjson users "$(cat $USERS_FILE)" '. + {users: $users}' $REALM_FILE  > "$REALM_FILE-tmp"
  jq --argjson clients "$(cat $CLIENTS_FILE)" '. + {clients: $clients}' "$REALM_FILE-tmp"  > "$REALM_FILE-tmp2"
  jq --argjson groups "$(cat $GROUPS_FILE)" '. + {groups: $groups}' "$REALM_FILE-tmp2"  > $VKDR_ENV_KEYCLOAK_EXPORT_FILE
  #cp $REALM_FILE "$VKDR_ENV_KEYCLOAK_EXPORT_FILE"
}

postExport() {
  info "Keycloak export realm finished!"
}

runFormula
