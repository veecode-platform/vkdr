#!/usr/bin/env bash

VKDR_ENV_POSTGRES_DATABASE_NAME=$1
VKDR_ENV_POSTGRES_USER_NAME=$2

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

POSTGRES_NAMESPACE=vkdr
POSTGRES_CLUSTER_NAME=vkdr-pg-cluster

startInfos() {
  boldInfo "Postgres Drop Database"
  bold "=============================="
  boldNotice "Database name: $VKDR_ENV_POSTGRES_DATABASE_NAME"
  boldNotice "User name: $VKDR_ENV_POSTGRES_USER_NAME"
  bold "=============================="
}

runFormula() {
  startInfos
  sanitizeVars
  dropDB
}

dropDB() {
  local POSTGRES_DB_OBJECT="${POSTGRES_CLUSTER_NAME}-${VKDR_ENV_POSTGRES_DATABASE_NAME}"
  local ROLE_SECRET_NAME="${POSTGRES_CLUSTER_NAME}-role-${VKDR_ENV_POSTGRES_USER_NAME}"
  local USER_PG_SECRET="${VKDR_ENV_POSTGRES_USER_NAME}-pg-secret"
  
  # Delete Database CRD if it exists
  if $VKDR_KUBECTL get database "$POSTGRES_DB_OBJECT" -n "$POSTGRES_NAMESPACE" &>/dev/null; then
    info "Deleting database '$VKDR_ENV_POSTGRES_DATABASE_NAME'..."
    $VKDR_KUBECTL delete database "$POSTGRES_DB_OBJECT" -n "$POSTGRES_NAMESPACE" --ignore-not-found=true
    boldInfo "Database '$VKDR_ENV_POSTGRES_DATABASE_NAME' deleted!"
  else
    debug "Database '$VKDR_ENV_POSTGRES_DATABASE_NAME' not found, skipping..."
  fi
  
  # Delete role from CloudNative-PG cluster if user name is provided
  if [ -n "$VKDR_ENV_POSTGRES_USER_NAME" ]; then
    deleteRole
    
    # Delete role secret if it exists
    if $VKDR_KUBECTL get secret "$ROLE_SECRET_NAME" -n "$POSTGRES_NAMESPACE" &>/dev/null; then
      info "Deleting role secret '$ROLE_SECRET_NAME'..."
      $VKDR_KUBECTL delete secret "$ROLE_SECRET_NAME" -n "$POSTGRES_NAMESPACE" --ignore-not-found=true
      boldInfo "Role secret '$ROLE_SECRET_NAME' deleted!"
    else
      debug "Role secret '$ROLE_SECRET_NAME' not found, skipping..."
    fi
    
    # Delete user-pg-secret if it exists (created by createdb with --store flag)
    if $VKDR_KUBECTL get secret "$USER_PG_SECRET" -n "$POSTGRES_NAMESPACE" &>/dev/null; then
      info "Deleting user secret '$USER_PG_SECRET'..."
      $VKDR_KUBECTL delete secret "$USER_PG_SECRET" -n "$POSTGRES_NAMESPACE" --ignore-not-found=true
      boldInfo "User secret '$USER_PG_SECRET' deleted!"
    else
      debug "User secret '$USER_PG_SECRET' not found, skipping..."
    fi
    
    # TODO: Delete vault database config and static-roles if they exist
    # This would require checking if vault is installed and configured
  fi
  
  info "Drop database completed successfully!"
}

deleteRole() {
  # Check if the role exists in the cluster managed roles
  local ROLE_INDEX=$($VKDR_KUBECTL get cluster "$POSTGRES_CLUSTER_NAME" -n "$POSTGRES_NAMESPACE" \
    -o json 2>/dev/null | $VKDR_JQ ".spec.managed.roles | map(.name) | index(\"${VKDR_ENV_POSTGRES_USER_NAME}\")")
  
  if [ "$ROLE_INDEX" != "null" ] && [ -n "$ROLE_INDEX" ]; then
    info "Removing role '$VKDR_ENV_POSTGRES_USER_NAME' from cluster..."
    
    # Set role ensure to "absent" to remove it
    $VKDR_KUBECTL patch cluster "$POSTGRES_CLUSTER_NAME" -n "$POSTGRES_NAMESPACE" --type=json \
      -p "[{\"op\": \"replace\", \"path\": \"/spec/managed/roles/${ROLE_INDEX}/ensure\", \"value\": \"absent\"}]"
    
    # Wait a moment for the operator to process the change
    sleep 2
    
    # Remove the role entry from the cluster spec
    $VKDR_KUBECTL patch cluster "$POSTGRES_CLUSTER_NAME" -n "$POSTGRES_NAMESPACE" --type=json \
      -p "[{\"op\": \"remove\", \"path\": \"/spec/managed/roles/${ROLE_INDEX}\"}]"
    
    boldInfo "Role '$VKDR_ENV_POSTGRES_USER_NAME' removed from cluster!"
  else
    debug "Role '$VKDR_ENV_POSTGRES_USER_NAME' not found in cluster, skipping..."
  fi
}

sanitizeVars() {
  # Set default user name to database name if not provided
  if [ -z "$VKDR_ENV_POSTGRES_USER_NAME" ]; then
    VKDR_ENV_POSTGRES_USER_NAME="$VKDR_ENV_POSTGRES_DATABASE_NAME"
    debug "User name not provided, using database name: $VKDR_ENV_POSTGRES_USER_NAME"
  fi
}

runFormula
