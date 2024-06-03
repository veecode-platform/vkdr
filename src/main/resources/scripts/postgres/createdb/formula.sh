#!/usr/bin/env bash

VKDR_ENV_POSTGRES_DATABASE_NAME=$1
VKDR_ENV_POSTGRES_ADMIN_PASSWORD=$2
VKDR_ENV_POSTGRES_USER_NAME=$3
VKDR_ENV_POSTGRES_PASSWORD=$4
VKDR_ENV_POSTGRES_STORE_SECRET=$5
VKDR_ENV_POSTGRES_DROP_DATABASE=$6

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

POSTGRES_NAMESPACE=vkdr

startInfos() {
  boldInfo "Postgres Create Database"
  bold "=============================="
  boldNotice "Database name: $VKDR_ENV_POSTGRES_DATABASE_NAME"
  boldNotice "Admin password: $VKDR_ENV_POSTGRES_ADMIN_PASSWORD"
  boldNotice "User name: $VKDR_ENV_POSTGRES_USER_NAME"
  boldNotice "Password: $VKDR_ENV_POSTGRES_PASSWORD"
  boldNotice "Store secret: $VKDR_ENV_POSTGRES_STORE_SECRET"
  boldNotice "Drop database: $VKDR_ENV_POSTGRES_DROP_DATABASE"
  bold "=============================="
}

runFormula() {
  startInfos
  sanitizeVars
  createDB
  saveSecret
}

createDB() {
  # $VKDR_ENV_POSTGRES_ADMIN_PASSWORD empty --> usa env var padrao
  if [ -z "$VKDR_ENV_POSTGRES_ADMIN_PASSWORD" ]; then
    boldInfo "Admin password is empty, will rely on container's internal POSTGRES_PASSWORD variable"
    if [ "true" = "$VKDR_ENV_POSTGRES_DROP_DATABASE" ]; then
      boldInfo "Dropping database $VKDR_ENV_POSTGRES_DATABASE_NAME if it exists..."
      $VKDR_KUBECTL exec postgres-postgresql-0 -n "$POSTGRES_NAMESPACE" -- sh -c "PGPASSWORD=\$POSTGRES_PASSWORD psql -U postgres -c \"DROP DATABASE IF EXISTS \\\"$VKDR_ENV_POSTGRES_DATABASE_NAME\\\";\""
      boldInfo "Dropping user/role $VKDR_ENV_POSTGRES_USER_NAME if it exists..."
      $VKDR_KUBECTL exec postgres-postgresql-0 -n "$POSTGRES_NAMESPACE" -- sh -c "PGPASSWORD=\$POSTGRES_PASSWORD psql -U postgres -c \"DROP ROLE IF EXISTS \\\"$VKDR_ENV_POSTGRES_USER_NAME\\\";\""
    fi
    boldInfo "Creating user..."
    $VKDR_KUBECTL exec postgres-postgresql-0 -n "$POSTGRES_NAMESPACE" -- sh -c "PGPASSWORD=\$POSTGRES_PASSWORD psql -U postgres -c \"CREATE ROLE \\\"$VKDR_ENV_POSTGRES_USER_NAME\\\" LOGIN PASSWORD '$VKDR_ENV_POSTGRES_PASSWORD';\""
    boldInfo "Creating database..." # tentar fazer "if not exists"
    $VKDR_KUBECTL exec postgres-postgresql-0 -n "$POSTGRES_NAMESPACE" -- sh -c "PGPASSWORD=\$POSTGRES_PASSWORD psql -U postgres -c \"CREATE DATABASE \\\"$VKDR_ENV_POSTGRES_DATABASE_NAME\\\" OWNER \\\"$VKDR_ENV_POSTGRES_USER_NAME\\\";\""
    boldInfo "Granting permissions to user..."
    $VKDR_KUBECTL exec postgres-postgresql-0 -n "$POSTGRES_NAMESPACE" -- sh -c "PGPASSWORD=\$POSTGRES_PASSWORD psql -U postgres -c \"GRANT ALL PRIVILEGES ON DATABASE \\\"$VKDR_ENV_POSTGRES_DATABASE_NAME\\\" TO \\\"$VKDR_ENV_POSTGRES_USER_NAME\\\";\""
  else
    if [ "true" = "$VKDR_ENV_POSTGRES_DROP_DATABASE" ]; then
      boldInfo "Dropping database $VKDR_ENV_POSTGRES_DATABASE_NAME if it exists..."
      $VKDR_KUBECTL exec postgres-postgresql-0 -n "$POSTGRES_NAMESPACE" -- sh -c "PGPASSWORD=\"$VKDR_ENV_POSTGRES_ADMIN_PASSWORD\" psql -U postgres -c \"DROP DATABASE IF EXISTS \\\"$VKDR_ENV_POSTGRES_DATABASE_NAME\\\";\""
      boldInfo "Dropping user/role $VKDR_ENV_POSTGRES_USER_NAME if it exists..."
      $VKDR_KUBECTL exec postgres-postgresql-0 -n "$POSTGRES_NAMESPACE" -- sh -c "PGPASSWORD=\"$VKDR_ENV_POSTGRES_ADMIN_PASSWORD\" psql -U postgres -c \"DROP ROLE IF EXISTS \\\"$VKDR_ENV_POSTGRES_USER_NAME\\\";\""
    fi
    boldInfo "Creating user..."
    $VKDR_KUBECTL exec postgres-postgresql-0 -n "$POSTGRES_NAMESPACE" -- sh -c "PGPASSWORD=\"$VKDR_ENV_POSTGRES_ADMIN_PASSWORD\" psql -U postgres -c \"CREATE ROLE \\\"$VKDR_ENV_POSTGRES_USER_NAME\\\" LOGIN PASSWORD '$VKDR_ENV_POSTGRES_PASSWORD';\""
    boldInfo "Creating database..." # tentar fazer "if not exists"
    $VKDR_KUBECTL exec postgres-postgresql-0 -n "$POSTGRES_NAMESPACE" -- sh -c "PGPASSWORD=\"$VKDR_ENV_POSTGRES_ADMIN_PASSWORD\" psql -U postgres -c \"CREATE DATABASE \\\"$VKDR_ENV_POSTGRES_DATABASE_NAME\\\" OWNER \\\"$VKDR_ENV_POSTGRES_USER_NAME\\\";\""
    boldInfo "Granting permissions to user..."
    $VKDR_KUBECTL exec postgres-postgresql-0 -n "$POSTGRES_NAMESPACE" -- sh -c "PGPASSWORD=\"$VKDR_ENV_POSTGRES_ADMIN_PASSWORD\" psql -U postgres -c \"GRANT ALL PRIVILEGES ON DATABASE \\\"$VKDR_ENV_POSTGRES_DATABASE_NAME\\\" TO \\\"$VKDR_ENV_POSTGRES_USER_NAME\\\";\""
  fi
}

saveSecret() {
  if [ "$VKDR_ENV_POSTGRES_STORE_SECRET" = "true" ]; then
    boldInfo "Storing secret in '$VKDR_ENV_POSTGRES_USER_NAME-pg-secret'..."
    $VKDR_KUBECTL delete secret "$VKDR_ENV_POSTGRES_USER_NAME-pg-secret" -n "$POSTGRES_NAMESPACE"
    $VKDR_KUBECTL create secret generic "$VKDR_ENV_POSTGRES_USER_NAME-pg-secret" -n "$POSTGRES_NAMESPACE" \
      --from-literal=password="$VKDR_ENV_POSTGRES_PASSWORD" \
      --from-literal=user="$VKDR_ENV_POSTGRES_USER_NAME" \
      --from-literal=dbname="$VKDR_ENV_POSTGRES_DATABASE_NAME"
  fi
}

sanitizeVars() {
  # todo: sanitize vars
  boldInfo "Sanitizing vars..."
}

runFormula
