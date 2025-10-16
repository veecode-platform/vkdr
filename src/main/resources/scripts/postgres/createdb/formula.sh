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
POSTGRES_CLUSTER_NAME=vkdr-pg-cluster
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
  # First, create the database owner role (user) with password
  createDatabaseRole
  
  # Then, create the database using CloudNative-PG Database CRD
  if [ "true" = "$VKDR_ENV_POSTGRES_DROP_DATABASE" ]; then
    boldInfo "Deleting existing Database resource if it exists..."
    kubectl delete database "${POSTGRES_CLUSTER_NAME}-${VKDR_ENV_POSTGRES_DATABASE_NAME}" \
      -n "$POSTGRES_NAMESPACE" --ignore-not-found
  fi
  
  boldInfo "Creating Database resource using CloudNative-PG CRD..."
  cat <<EOF | kubectl apply -f -
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: ${POSTGRES_CLUSTER_NAME}-${VKDR_ENV_POSTGRES_DATABASE_NAME}
  namespace: ${POSTGRES_NAMESPACE}
spec:
  name: ${VKDR_ENV_POSTGRES_DATABASE_NAME}
  owner: ${VKDR_ENV_POSTGRES_USER_NAME}
  cluster:
    name: ${POSTGRES_CLUSTER_NAME}
EOF
  
  # Wait for database to be created
  info "Waiting for database to be reconciled..."
  kubectl wait --for=jsonpath='{.status.applied}'=true --timeout=60s \
    database/"${POSTGRES_CLUSTER_NAME}-${VKDR_ENV_POSTGRES_DATABASE_NAME}" -n "$POSTGRES_NAMESPACE" || true
  
  boldInfo "Database created successfully!"
}

createDatabaseRole() {
  boldInfo "Creating database role (user) ${VKDR_ENV_POSTGRES_USER_NAME} using declarative role management..."
  
  # First, create the password secret for the role
  local ROLE_SECRET_NAME="${POSTGRES_CLUSTER_NAME}-role-${VKDR_ENV_POSTGRES_USER_NAME}"
  
  if [ "true" = "$VKDR_ENV_POSTGRES_DROP_DATABASE" ]; then
    boldInfo "Deleting existing role secret if it exists..."
    kubectl delete secret "$ROLE_SECRET_NAME" -n "$POSTGRES_NAMESPACE" --ignore-not-found
  fi
  
  debug "Creating role password secret: $ROLE_SECRET_NAME"
  kubectl create secret generic "$ROLE_SECRET_NAME" \
    -n "$POSTGRES_NAMESPACE" \
    --from-literal=username="$VKDR_ENV_POSTGRES_USER_NAME" \
    --from-literal=password="$VKDR_ENV_POSTGRES_PASSWORD" \
    --dry-run=client -o yaml | kubectl apply -f -
  
  # Add label for CloudNative-PG to reload the secret
  kubectl label secret "$ROLE_SECRET_NAME" -n "$POSTGRES_NAMESPACE" \
    "cnpg.io/reload=true" --overwrite
  
  # Determine ensure value based on drop flag
  local ENSURE_VALUE="present"
  if [ "true" = "$VKDR_ENV_POSTGRES_DROP_DATABASE" ]; then
    # First set to absent to remove the role if it exists
    ENSURE_VALUE="absent"
    debug "Setting role to absent to remove it first..."
    patchClusterWithRole "$ENSURE_VALUE" "$ROLE_SECRET_NAME"
    sleep 2
    ENSURE_VALUE="present"
  fi
  
  # Patch the Cluster CRD to add the managed role
  debug "Patching Cluster CRD to add managed role..."
  patchClusterWithRole "$ENSURE_VALUE" "$ROLE_SECRET_NAME"
  
  boldInfo "Role ${VKDR_ENV_POSTGRES_USER_NAME} configured successfully!"
}

patchClusterWithRole() {
  local ENSURE="$1"
  local SECRET_NAME="$2"
  
  # Create the role configuration
  local ROLE_CONFIG=$(cat <<EOF
{
  "spec": {
    "managed": {
      "roles": [
        {
          "name": "${VKDR_ENV_POSTGRES_USER_NAME}",
          "ensure": "${ENSURE}",
          "login": true,
          "passwordSecret": {
            "name": "${SECRET_NAME}"
          }
        }
      ]
    }
  }
}
EOF
)
  
  # Check if managed.roles already exists
  local EXISTING_ROLES=$(kubectl get cluster "$POSTGRES_CLUSTER_NAME" -n "$POSTGRES_NAMESPACE" \
    -o jsonpath='{.spec.managed.roles}' 2>/dev/null || echo "[]")
  
  if [ "$EXISTING_ROLES" = "[]" ] || [ -z "$EXISTING_ROLES" ]; then
    # No existing roles, use strategic merge patch
    echo "$ROLE_CONFIG" | kubectl patch cluster "$POSTGRES_CLUSTER_NAME" \
      -n "$POSTGRES_NAMESPACE" --type=merge --patch-file=/dev/stdin
  else
    # Roles exist, need to append or update
    # For simplicity, we'll use kubectl patch with JSON patch to add/update the role
    local ROLE_INDEX=$(kubectl get cluster "$POSTGRES_CLUSTER_NAME" -n "$POSTGRES_NAMESPACE" \
      -o json | jq ".spec.managed.roles | map(.name) | index(\"${VKDR_ENV_POSTGRES_USER_NAME}\")")
    
    if [ "$ROLE_INDEX" = "null" ]; then
      # Role doesn't exist, append it
      kubectl patch cluster "$POSTGRES_CLUSTER_NAME" -n "$POSTGRES_NAMESPACE" --type=json \
        -p "[{\"op\": \"add\", \"path\": \"/spec/managed/roles/-\", \"value\": {\"name\": \"${VKDR_ENV_POSTGRES_USER_NAME}\", \"ensure\": \"${ENSURE}\", \"login\": true, \"passwordSecret\": {\"name\": \"${SECRET_NAME}\"}}}]"
    else
      # Role exists, update it
      kubectl patch cluster "$POSTGRES_CLUSTER_NAME" -n "$POSTGRES_NAMESPACE" --type=json \
        -p "[{\"op\": \"replace\", \"path\": \"/spec/managed/roles/${ROLE_INDEX}\", \"value\": {\"name\": \"${VKDR_ENV_POSTGRES_USER_NAME}\", \"ensure\": \"${ENSURE}\", \"login\": true, \"passwordSecret\": {\"name\": \"${SECRET_NAME}\"}}}]"
    fi
  fi
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
      connection_url="postgresql://{{username}}:{{password}}@${POSTGRES_CLUSTER_NAME}-rw:5432/$VKDR_ENV_POSTGRES_DATABASE_NAME" \
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
    kubectl get secret "${POSTGRES_CLUSTER_NAME}-superuser" -n "$POSTGRES_NAMESPACE" -o jsonpath='{.data.password}' | base64 -d
  else
    echo "$VKDR_ENV_POSTGRES_ADMIN_PASSWORD"
  fi
}

sanitizeVars() {
  # todo: sanitize vars
  boldInfo "Sanitizing vars..."
}

runFormula
