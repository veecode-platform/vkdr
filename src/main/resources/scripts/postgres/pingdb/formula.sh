#!/usr/bin/env bash

VKDR_ENV_POSTGRES_DATABASE_NAME=$1
VKDR_ENV_POSTGRES_USER_NAME=$2

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

POSTGRES_NAMESPACE=vkdr
POSTGRES_CLUSTER_NAME=vkdr-pg-cluster

startInfos() {
  boldInfo "Postgres Ping Database"
  bold "=============================="
  boldNotice "Database: $VKDR_ENV_POSTGRES_DATABASE_NAME"
  boldNotice "User: $VKDR_ENV_POSTGRES_USER_NAME"
  bold "=============================="
}

runFormula() {
  startInfos
  pingDatabase
}

pingDatabase() {
  local ROLE_SECRET_NAME="${POSTGRES_CLUSTER_NAME}-role-${VKDR_ENV_POSTGRES_USER_NAME}"
  local HOSTNAME="${POSTGRES_CLUSTER_NAME}-rw"
  local PORT="5432"
  
  # Check if role secret exists
  if ! $VKDR_KUBECTL get secret "$ROLE_SECRET_NAME" -n "$POSTGRES_NAMESPACE" &>/dev/null; then
    error "Role secret '$ROLE_SECRET_NAME' not found in namespace '$POSTGRES_NAMESPACE'"
    error "Make sure the database and user were created with 'vkdr postgres createdb'"
    exit 1
  fi
  
  # Read password from secret
  debug "Reading password from secret '$ROLE_SECRET_NAME'..."
  local PASSWORD=$($VKDR_KUBECTL get secret "$ROLE_SECRET_NAME" -n "$POSTGRES_NAMESPACE" \
    -o jsonpath='{.data.password}' | base64 -d)
  
  if [ -z "$PASSWORD" ]; then
    error "Failed to read password from secret '$ROLE_SECRET_NAME'"
    exit 1
  fi
  
  # Get the primary pod name
  local PRIMARY_POD=$($VKDR_KUBECTL get pod -n "$POSTGRES_NAMESPACE" \
    -l "cnpg.io/cluster=${POSTGRES_CLUSTER_NAME},role=primary" \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  
  if [ -z "$PRIMARY_POD" ]; then
    error "Could not find primary pod for cluster '$POSTGRES_CLUSTER_NAME'"
    exit 1
  fi
  
  debug "Using primary pod: $PRIMARY_POD"
  
  # Test connection using psql
  info "Testing connection to database '$VKDR_ENV_POSTGRES_DATABASE_NAME' as user '$VKDR_ENV_POSTGRES_USER_NAME'..."
  
  $VKDR_KUBECTL exec -n "$POSTGRES_NAMESPACE" "$PRIMARY_POD" -c postgres -- \
    env PGPASSWORD="$PASSWORD" psql \
      -h "$HOSTNAME" \
      -p "$PORT" \
      -U "$VKDR_ENV_POSTGRES_USER_NAME" \
      -d "$VKDR_ENV_POSTGRES_DATABASE_NAME" \
      -c "SELECT 1 AS ping;" 2>/dev/null
  
  if [ $? -eq 0 ]; then
    boldInfo "✓ Database connection successful!"
    info "Connection details:"
    info "  Host: $HOSTNAME:$PORT"
    info "  Database: $VKDR_ENV_POSTGRES_DATABASE_NAME"
    info "  User: $VKDR_ENV_POSTGRES_USER_NAME"
    return 0
  else
    error "✗ Database connection failed!"
    error "Please check:"
    error "  - Database exists: vkdr postgres listdbs"
    error "  - User has permissions on the database"
    error "  - Password is correct in secret: $ROLE_SECRET_NAME"
    exit 1
  fi
}

runFormula
