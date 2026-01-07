#!/usr/bin/env bash

VKDR_ENV_KEYCLOAK_EXPORT_FILE=$1
VKDR_ENV_KEYCLOAK_REALM=$2
VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD=$3

# V2 paths: relative to formulas/keycloak/export/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

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
  ROLES_FILE=/tmp/roles-export-$RAND_SUFIX.json
  CLIENT_SCOPES_FILE=/tmp/client-scopes-export-$RAND_SUFIX.json
  AUTH_FLOWS_FILE=/tmp/auth-flows-export-$RAND_SUFIX.json
  IDENTITY_PROVIDERS_FILE=/tmp/identity-providers-export-$RAND_SUFIX.json

  debug "export: keycloak config credentials into $KCADM_CONFIG"
  $VKDR_KUBECTL exec "$KEYCLOAK_POD_NAME" -c keycloak -n "$KEYCLOAK_NAMESPACE" -- sh -c "kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password $VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD --config $KCADM_CONFIG"

  debug "export: keycloak export realm into $REALM_FILE"
  $VKDR_KUBECTL exec "$KEYCLOAK_POD_NAME" -c keycloak -n "$KEYCLOAK_NAMESPACE" -- sh -c "kcadm.sh get realms/$VKDR_ENV_KEYCLOAK_REALM --config $KCADM_CONFIG" > $REALM_FILE

  debug "export: keycloak export users into $USERS_FILE"
  $VKDR_KUBECTL exec "$KEYCLOAK_POD_NAME" -c keycloak -n "$KEYCLOAK_NAMESPACE" -- sh -c "kcadm.sh get users -r $VKDR_ENV_KEYCLOAK_REALM --config $KCADM_CONFIG --fields 'id,username,enabled,emailVerified,firstName,lastName,email,attributes,requiredActions,groups,clientRoles,realmRoles,federatedIdentities,credentials'" > $USERS_FILE

  debug "export: keycloak export groups into $GROUPS_FILE"
  $VKDR_KUBECTL exec "$KEYCLOAK_POD_NAME" -c keycloak -n "$KEYCLOAK_NAMESPACE" -- sh -c "kcadm.sh get groups -r $VKDR_ENV_KEYCLOAK_REALM --config $KCADM_CONFIG --fields 'id,name,path,attributes,realmRoles,clientRoles,subGroups'" > $GROUPS_FILE

  debug "export: keycloak export clients into $CLIENTS_FILE"
  $VKDR_KUBECTL exec "$KEYCLOAK_POD_NAME" -c keycloak -n "$KEYCLOAK_NAMESPACE" -- sh -c "kcadm.sh get clients -r $VKDR_ENV_KEYCLOAK_REALM --config $KCADM_CONFIG --fields '*'" > $CLIENTS_FILE

  debug "export: keycloak export realm roles into $ROLES_FILE"
  $VKDR_KUBECTL exec "$KEYCLOAK_POD_NAME" -c keycloak -n "$KEYCLOAK_NAMESPACE" -- sh -c "kcadm.sh get roles -r $VKDR_ENV_KEYCLOAK_REALM --config $KCADM_CONFIG" > $ROLES_FILE

  debug "export: keycloak export client scopes into $CLIENT_SCOPES_FILE"
  $VKDR_KUBECTL exec "$KEYCLOAK_POD_NAME" -c keycloak -n "$KEYCLOAK_NAMESPACE" -- sh -c "kcadm.sh get client-scopes -r $VKDR_ENV_KEYCLOAK_REALM --config $KCADM_CONFIG" > $CLIENT_SCOPES_FILE

  debug "export: keycloak export authentication flows into $AUTH_FLOWS_FILE"
  $VKDR_KUBECTL exec "$KEYCLOAK_POD_NAME" -c keycloak -n "$KEYCLOAK_NAMESPACE" -- sh -c "kcadm.sh get authentication/flows -r $VKDR_ENV_KEYCLOAK_REALM --config $KCADM_CONFIG" > $AUTH_FLOWS_FILE

  debug "export: keycloak export identity providers into $IDENTITY_PROVIDERS_FILE"
  $VKDR_KUBECTL exec "$KEYCLOAK_POD_NAME" -c keycloak -n "$KEYCLOAK_NAMESPACE" -- sh -c "kcadm.sh get identity-provider/instances -r $VKDR_ENV_KEYCLOAK_REALM --config $KCADM_CONFIG" > $IDENTITY_PROVIDERS_FILE

  debug "export: Merging all data into realm file $VKDR_ENV_KEYCLOAK_EXPORT_FILE"
  jq --argjson users "$(cat $USERS_FILE)" \
     --argjson clients "$(cat $CLIENTS_FILE)" \
     --argjson groups "$(cat $GROUPS_FILE)" \
     --argjson roles "$(cat $ROLES_FILE)" \
     --argjson clientScopes "$(cat $CLIENT_SCOPES_FILE)" \
     --argjson authenticationFlows "$(cat $AUTH_FLOWS_FILE)" \
     --argjson identityProviders "$(cat $IDENTITY_PROVIDERS_FILE)" \
     '. + {
       users: $users,
       clients: $clients,
       groups: $groups,
       roles: $roles,
       clientScopes: $clientScopes,
       authenticationFlows: $authenticationFlows,
       identityProviders: $identityProviders
     }' $REALM_FILE > $VKDR_ENV_KEYCLOAK_EXPORT_FILE

  debug "export: Cleaning up temporary files"
  rm -f "$REALM_FILE" "$USERS_FILE" "$GROUPS_FILE" "$CLIENTS_FILE" "$ROLES_FILE" "$CLIENT_SCOPES_FILE" "$AUTH_FLOWS_FILE" "$IDENTITY_PROVIDERS_FILE" "$KCADM_CONFIG"
}

postExport() {
  info "Keycloak export realm finished!"
}

runFormula
