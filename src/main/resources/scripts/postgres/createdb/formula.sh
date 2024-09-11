#!/usr/bin/env bash

VKDR_ENV_POSTGRES_DATABASE_NAME=$1
VKDR_ENV_POSTGRES_ADMIN_PASSWORD=$2
VKDR_ENV_POSTGRES_USER_NAME=$3
VKDR_ENV_POSTGRES_PASSWORD=$4
VKDR_ENV_POSTGRES_STORE_SECRET=$5
VKDR_ENV_POSTGRES_DROP_DATABASE=$6
VKDR_ENV_POSTGRES_CREATE_VAULT=$7
VKDR_ENV_POSTGRES_VAULT_ROTATION_SCHEDULE=$8

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"
source "$(dirname "$0")/../../.util/vault-tools.sh"

POSTGRES_NAMESPACE=vkdr
VAULT_NAMESPACE=vkdr

startInfos() {
  boldInfo "Postgres Create Database"
  bold "=============================="
  boldNotice "Database name: $VKDR_ENV_POSTGRES_DATABASE_NAME"
  boldNotice "Admin password: $VKDR_ENV_POSTGRES_ADMIN_PASSWORD"
  boldNotice "User name: $VKDR_ENV_POSTGRES_USER_NAME"
  boldNotice "Password: $VKDR_ENV_POSTGRES_PASSWORD"
  boldNotice "Store secret: $VKDR_ENV_POSTGRES_STORE_SECRET"
  boldNotice "Drop database: $VKDR_ENV_POSTGRES_DROP_DATABASE"
  boldNotice "Create vault database config: $VKDR_ENV_POSTGRES_CREATE_VAULT"
  boldNotice "Vault rotation schedule: $VKDR_ENV_POSTGRES_VAULT_ROTATION_SCHEDULE"
  bold "=============================="
}

runFormula() {
  startInfos
  sanitizeVars
  createDB
  createVaultConfig
  saveSecret
}

createDB() {
  VKDR_CREATEROLE=""
  #if [ "$VKDR_ENV_POSTGRES_CREATE_VAULT" = "true" ]; then
  #  debug "createDB: create_vault enabled, will assign CREATEROLE to database role $VKDR_ENV_POSTGRES_USER_NAME..."
  #  VKDR_CREATEROLE="CREATEROLE"
  #fi
  VKDR_PG_PWD=$(getPgAdminPassword)
  if [ "true" = "$VKDR_ENV_POSTGRES_DROP_DATABASE" ]; then
    boldInfo "Dropping database $VKDR_ENV_POSTGRES_DATABASE_NAME if it exists..."
    $VKDR_KUBECTL exec postgres-postgresql-0 -n "$POSTGRES_NAMESPACE" -- sh -c "PGPASSWORD=\"$VKDR_PG_PWD\" psql -U postgres -c \"DROP DATABASE IF EXISTS \\\"$VKDR_ENV_POSTGRES_DATABASE_NAME\\\";\""
    boldInfo "Dropping user/role $VKDR_ENV_POSTGRES_USER_NAME if it exists..."
    $VKDR_KUBECTL exec postgres-postgresql-0 -n "$POSTGRES_NAMESPACE" -- sh -c "PGPASSWORD=\"$VKDR_PG_PWD\" psql -U postgres -c \"DROP ROLE IF EXISTS \\\"$VKDR_ENV_POSTGRES_USER_NAME\\\";\""
  fi
  boldInfo "Creating user..."
  $VKDR_KUBECTL exec postgres-postgresql-0 -n "$POSTGRES_NAMESPACE" -- sh -c "PGPASSWORD=\"$VKDR_PG_PWD\" psql -U postgres -c \"CREATE ROLE \\\"$VKDR_ENV_POSTGRES_USER_NAME\\\" $VKDR_CREATEROLE LOGIN PASSWORD '$VKDR_ENV_POSTGRES_PASSWORD';\""
  boldInfo "Creating database..." # tentar fazer "if not exists"
  $VKDR_KUBECTL exec postgres-postgresql-0 -n "$POSTGRES_NAMESPACE" -- sh -c "PGPASSWORD=\"$VKDR_PG_PWD\" psql -U postgres -c \"CREATE DATABASE \\\"$VKDR_ENV_POSTGRES_DATABASE_NAME\\\" OWNER \\\"$VKDR_ENV_POSTGRES_USER_NAME\\\";\""
  boldInfo "Granting permissions to user..."
  $VKDR_KUBECTL exec postgres-postgresql-0 -n "$POSTGRES_NAMESPACE" -- sh -c "PGPASSWORD=\"$VKDR_PG_PWD\" psql -U postgres -c \"GRANT ALL PRIVILEGES ON DATABASE \\\"$VKDR_ENV_POSTGRES_DATABASE_NAME\\\" TO \\\"$VKDR_ENV_POSTGRES_USER_NAME\\\";\""
}

#
# vault write database/config/kong plugin_name="postgresql-database-plugin" \
# connection_url="postgresql://{{username}}:{{password}}@postgres-postgresql:5432/kong" \
# username=kong password=kongpwd allowed_roles="kong"
#
# vault write database/roles/kong db_name=kong \
# creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
#        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; \
#        GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\"; \
#        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO \"{{name}}\"; \
#        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO \"{{name}}\";" \
#      default_ttl="1h" \
#      max_ttl="24h"
#
createVaultConfig() {
  if [ "$VKDR_ENV_POSTGRES_CREATE_VAULT" != "true" ]; then
    debug "createVaultConfig: will not create vault config, skipping..."
    return
  fi
  debug "createVaultConfig: fetching vault token and PG admin password"
  VKDR_VAULT_TOKEN=$(getVaultToken)
  VKDR_PG_PWD=$(getPgAdminPassword)
  debug "createVaultConfig: creating vault database/config/$VKDR_ENV_POSTGRES_DATABASE_NAME..."
  $VKDR_KUBECTL -n $VAULT_NAMESPACE exec vault-0 -- env VAULT_TOKEN=$VKDR_VAULT_TOKEN \
    vault write database/config/$VKDR_ENV_POSTGRES_DATABASE_NAME \
      plugin_name="postgresql-database-plugin" \
      allowed_roles="$VKDR_ENV_POSTGRES_DATABASE_NAME" \
      connection_url="postgresql://{{username}}:{{password}}@postgres-postgresql:5432/$VKDR_ENV_POSTGRES_DATABASE_NAME" \
      username="postgres" \
      password="$VKDR_PG_PWD"
  debug "createVaultConfig: creating vault database/static-roles/$VKDR_ENV_POSTGRES_DATABASE_NAME..."
  $VKDR_KUBECTL -n $VAULT_NAMESPACE exec vault-0 -- env VAULT_TOKEN=$VKDR_VAULT_TOKEN \
    vault write database/static-roles/$VKDR_ENV_POSTGRES_USER_NAME \
        db_name=$VKDR_ENV_POSTGRES_DATABASE_NAME \
        username="$VKDR_ENV_POSTGRES_USER_NAME" \
        rotation_schedule="$VKDR_ENV_POSTGRES_VAULT_ROTATION_SCHEDULE"
}

saveSecret() {
  if [ "$VKDR_ENV_POSTGRES_STORE_SECRET" != "true" ]; then
    return
  fi
  if [ "$VKDR_ENV_POSTGRES_CREATE_VAULT" != "true" ]; then
    boldInfo "Storing plain secret in '$VKDR_ENV_POSTGRES_USER_NAME-pg-secret'..."
    $VKDR_KUBECTL delete secret "$VKDR_ENV_POSTGRES_USER_NAME-pg-secret" -n "$POSTGRES_NAMESPACE" --ignore-not-found=true
    $VKDR_KUBECTL create secret generic "$VKDR_ENV_POSTGRES_USER_NAME-pg-secret" -n "$POSTGRES_NAMESPACE" \
      --from-literal=password="$VKDR_ENV_POSTGRES_PASSWORD" \
      --from-literal=user="$VKDR_ENV_POSTGRES_USER_NAME" \
      --from-literal=dbname="$VKDR_ENV_POSTGRES_DATABASE_NAME"
  else
    boldInfo "Storing secret in '$VKDR_ENV_POSTGRES_USER_NAME-pg-secret' using ESO CRDs and Vault..."
    # todo: delete ESO CRDs on removal
    sed "s/\${user_name}/$VKDR_ENV_POSTGRES_USER_NAME/g" "$(dirname "$0")/../../.util/values/eso-crds-template.yaml" \
      | sed "s/\${db_name}/$VKDR_ENV_POSTGRES_DATABASE_NAME/g" \
      | $VKDR_KUBECTL apply -f -
  fi
}

getPgAdminPassword() {
  if [ -z "$VKDR_ENV_POSTGRES_ADMIN_PASSWORD" ]; then
    $VKDR_KUBECTL exec postgres-postgresql-0 -n "$POSTGRES_NAMESPACE" -- sh -c "echo \$POSTGRES_PASSWORD"
  else
    echo "$VKDR_ENV_POSTGRES_ADMIN_PASSWORD"
  fi
}

sanitizeVars() {
  # todo: sanitize vars
  boldInfo "Sanitizing vars..."
}

runFormula
