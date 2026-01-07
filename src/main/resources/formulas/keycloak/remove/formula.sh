#!/usr/bin/env bash

# V2 paths: relative to formulas/keycloak/remove/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

KEYCLOAK_NAMESPACE=keycloak
DB_NAMESPACE=vkdr

KEYCLOAK_SERVER_YAML="$SHARED_DIR/operators/keycloak/keycloak-server.yml"
KEYCLOAK_BOOTSTRAP_SECRET=vkdr-keycloak-bootstrap-admin-user

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
  # Delete database and its secrets using 'vkdr postgres dropdb'
  if command -v vkdr &>/dev/null; then
    info "Dropping Keycloak database and associated secrets..."
    vkdr postgres dropdb -d "$POSTGRES_DB_NAME" -u "$POSTGRES_USER"
  else
    error "removeKeycloak: vkdr command not found, cannot drop database"
  fi
  # Delete bootstrap secret
  info "Deleting Keycloak bootstrap secret..."
  $VKDR_KUBECTL delete secret "$KEYCLOAK_BOOTSTRAP_SECRET" -n "$KEYCLOAK_NAMESPACE" --ignore-not-found=true
  # Delete keycloak-db-secret (created from postgres role secret)
  info "Deleting Keycloak database secret..."
  $VKDR_KUBECTL delete secret keycloak-db-secret -n "$KEYCLOAK_NAMESPACE" --ignore-not-found=true

  info "Keycloak removed successfully!"
}

runFormula
