#!/usr/bin/env bash

VKDR_ENV_POSTGRES_JSON=$1

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

POSTGRES_NAMESPACE=vkdr
POSTGRES_CLUSTER_NAME=vkdr-pg-cluster

startInfos() {
  if [ "$VKDR_ENV_POSTGRES_JSON" = "true" ]; then
    debug "Postgres List Databases (JSON output)"
  else
    boldInfo "Postgres List Databases"
    bold "=============================="
  fi
}

runFormula() {
  startInfos
  listDatabases
}

listDatabases() {
  # Get the primary pod name
  local PRIMARY_POD=$($VKDR_KUBECTL get pod -n "$POSTGRES_NAMESPACE" \
    -l "cnpg.io/cluster=${POSTGRES_CLUSTER_NAME},role=primary" \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  
  if [ -z "$PRIMARY_POD" ]; then
    error "Could not find primary pod for cluster '$POSTGRES_CLUSTER_NAME'"
    exit 1
  fi
  
  debug "Using primary pod: $PRIMARY_POD"
  
  if [ "$VKDR_ENV_POSTGRES_JSON" = "true" ]; then
    # Query pg_database and format as JSON using row_to_json
    local SQL_QUERY="SELECT json_agg(row_to_json(t)) FROM (SELECT datname AS name, pg_catalog.pg_get_userbyid(datdba) AS owner, pg_encoding_to_char(encoding) AS encoding, datcollate AS collate, datctype AS ctype, pg_database_size(datname) AS size FROM pg_database WHERE datname NOT IN ('template0') ORDER BY datname) t;"
    
    $VKDR_KUBECTL exec -n "$POSTGRES_NAMESPACE" "$PRIMARY_POD" -c postgres -- \
      psql -U postgres -t -A -c "$SQL_QUERY"
    
    if [ $? -eq 0 ]; then
      debug "Database list completed successfully!"
      return 0
    else
      error "Failed to list databases"
      exit 1
    fi
  else
    # Use standard \l command for text output
    $VKDR_KUBECTL exec -n "$POSTGRES_NAMESPACE" "$PRIMARY_POD" -c postgres -- \
      psql -U postgres -c '\l' 2>/dev/null
    
    if [ $? -eq 0 ]; then
      debug "Database list completed successfully!"
      return 0
    else
      error "Failed to list databases"
      exit 1
    fi
  fi
}

runFormula
