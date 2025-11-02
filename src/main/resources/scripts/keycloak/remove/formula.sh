#!/usr/bin/env bash

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

KEYCLOAK_NAMESPACE=keycloak
DB_NAMESPACE=vkdr

KEYCLOAK_SERVER_YAML="$(dirname "$0")/../../.util/operators/keycloak/keycloak-server.yml"

startInfos() {
  boldInfo "Keycloak Remove"
  bold "=============================="
}

runFormula() {
  startInfos
  removeKeycloak
}

removeKeycloak() {
  POSTGRES_DB_NAME="keycloak"
  POSTGRES_USER="keycloak"
  
  # Delete Keycloak server CR
  if $VKDR_KUBECTL get keycloak vkdr-keycloak -n $KEYCLOAK_NAMESPACE &>/dev/null; then
    info "Deleting Keycloak server..."
    $VKDR_KUBECTL delete -f "$KEYCLOAK_SERVER_YAML" -n "$KEYCLOAK_NAMESPACE" --ignore-not-found=true
  fi
  
  # Delete admin secret
  info "Deleting Keycloak admin secret..."
  $VKDR_KUBECTL delete secret vkdr-keycloak-initial-admin -n "$KEYCLOAK_NAMESPACE" --ignore-not-found=true
  
  # Delete keycloak-db-secret (created from postgres role secret)
  info "Deleting Keycloak database secret..."
  $VKDR_KUBECTL delete secret keycloak-db-secret -n "$KEYCLOAK_NAMESPACE" --ignore-not-found=true
  
  # Delete database and its secrets using 'vkdr postgres dropdb'
  if command -v vkdr &>/dev/null; then
    info "Dropping Keycloak database and associated secrets..."
    vkdr postgres dropdb -d "$POSTGRES_DB_NAME" -u "$POSTGRES_USER"
  else
    error "removeKeycloak: vkdr command not found, cannot drop database"
  fi
  
  info "Keycloak removed successfully!"
}

runFormula
