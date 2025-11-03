#!/usr/bin/env bash

VKDR_ENV_KEYCLOAK_DOMAIN=$1
VKDR_ENV_KEYCLOAK_SECURE=$2
VKDR_ENV_KEYCLOAK_ADMIN_USER=$3
VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD=$4

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"
source "$(dirname "$0")/../../.util/ingress-tools.sh"

KEYCLOAK_NAMESPACE=keycloak
DB_NAMESPACE=vkdr
# port values override by detectClusterPorts
VKDR_HTTP_PORT=8000
VKDR_HTTPS_PORT=8001

KEYCLOAK_OPERATOR_YAML="$(dirname "$0")/../../.util/operators/keycloak/keycloak-operator.yml"
KEYCLOAK_CRD_YAML="$(dirname "$0")/../../.util/operators/keycloak/keycloakrealmimports.k8s.keycloak.org-v1.yml"
KEYCLOAK_IMPORT_YAML="$(dirname "$0")/../../.util/operators/keycloak/keycloaks.k8s.keycloak.org-v1.yml"
KEYCLOAK_SERVER_YAML="$(dirname "$0")/../../.util/operators/keycloak/keycloak-server.yml"
KEYCLOAK_BOOTSTRAP_SECRET=vkdr-keycloak-bootstrap-admin-user
KEYCLOAK_FINAL_SERVER_YAML="$KEYCLOAK_SERVER_YAML"

startInfos() {
  boldInfo "Keycloak Install"
  bold "=============================="
  boldNotice "Domain: $VKDR_ENV_KEYCLOAK_DOMAIN"
  boldNotice "Secure: $VKDR_ENV_KEYCLOAK_SECURE"
  boldNotice "Admin User: $VKDR_ENV_KEYCLOAK_ADMIN_USER"
  boldNotice "Admin Password: $VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD"
  bold "=============================="
  boldNotice "Cluster LB HTTP port: $VKDR_HTTP_PORT"
  boldNotice "Cluster LB HTTPS port: $VKDR_HTTPS_PORT"
  bold "=============================="
}

runFormula() {
  detectClusterPorts
  startInfos
  createNamespace
  configure
  configDomain
  ensurePostgresDatabase
  ensurePostgresSecret
  ensureAdminSecret
  install
  postInstall
}

configure() {
  # Install Keycloak operator if not already installed
  if ! kubectl get deployment keycloak-operator -n keycloak &>/dev/null; then
    debug "install: deploying Keycloak operator"
    kubectl apply --server-side -f "$KEYCLOAK_CRD_YAML"
    kubectl apply --server-side -f "$KEYCLOAK_IMPORT_YAML"
    kubectl apply --server-side -f "$KEYCLOAK_OPERATOR_YAML" -n keycloak
    info "Waiting for Keycloak operator to be ready..."
    kubectl wait --for=condition=Available --timeout=300s \
      deployment/keycloak-operator -n keycloak
  else
    info "Keycloak operator already installed, skipping..."
  fi
  # copies server yaml file to temp file
  cp "$KEYCLOAK_SERVER_YAML" /tmp/keycloak-server.yml
  KEYCLOAK_FINAL_SERVER_YAML="/tmp/keycloak-server.yml"

  # if there is a "keycloak-pg-secret" use those credentials and do not install postgres subchart
  # if $VKDR_KUBECTL get secrets -n $KEYCLOAK_NAMESPACE | grep -q "keycloak-pg-secret" ; then
  #   VKDR_KEYCLOAK_SECRET_VALUES="$(dirname "$0")"/../../.util/values/delta-keycloak-std-dbsecrets.yaml
  #   YAML_TMP_FILE_SECRET=/tmp/keycloak-secret-std.yaml
  #   $VKDR_YQ eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' $VKDR_KEYCLOAK_VALUES $VKDR_KEYCLOAK_SECRET_VALUES > $YAML_TMP_FILE_SECRET
  #   VKDR_KEYCLOAK_VALUES=$YAML_TMP_FILE_SECRET
  # fi
}

ensureAdminSecret() {
  # if there is no secret "vkdr-keycloak-initial-admin" in namespace "$KEYCLOAK_NAMESPACE"
  # create this secret with the VKDR_ENV_KEYCLOAK_ADMIN_USER and VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD
  if ! $VKDR_KUBECTL get secret "$KEYCLOAK_BOOTSTRAP_SECRET" -n "$KEYCLOAK_NAMESPACE" &>/dev/null; then
    debug "ensureAdminSecret: creating '$KEYCLOAK_BOOTSTRAP_SECRET' secret with admin credentials"
    
    # Create new secret with admin username and password from environment variables
    $VKDR_KUBECTL create secret generic "$KEYCLOAK_BOOTSTRAP_SECRET" \
      --from-literal=username="$VKDR_ENV_KEYCLOAK_ADMIN_USER" \
      --from-literal=password="$VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD" \
      -n "$KEYCLOAK_NAMESPACE"
    
    info "ensureAdminSecret: created '$KEYCLOAK_BOOTSTRAP_SECRET' with admin credentials"
  else
    debug "ensureAdminSecret: '$KEYCLOAK_BOOTSTRAP_SECRET' already exists"
  fi
}

ensurePostgresSecret() {
  # if there is no secret "keycloak-db-secret" in namespace "$KEYCLOAK_NAMESPACE"
  # extract username and password from the postgres secret and create a new secret with those fields
  if ! $VKDR_KUBECTL get secret "keycloak-db-secret" -n "$KEYCLOAK_NAMESPACE" &>/dev/null; then
    debug "ensurePostgresSecret: copying username and password from '${POSTGRES_CLUSTER_NAME}-role-${POSTGRES_USER}' secret"
    
    # Extract username and password from the source secret
    USERNAME=$($VKDR_KUBECTL get secret "${POSTGRES_CLUSTER_NAME}-role-${POSTGRES_USER}" -n "$DB_NAMESPACE" -o jsonpath='{.data.username}')
    PASSWORD=$($VKDR_KUBECTL get secret "${POSTGRES_CLUSTER_NAME}-role-${POSTGRES_USER}" -n "$DB_NAMESPACE" -o jsonpath='{.data.password}')
    
    # Create new secret with only username and password fields
    $VKDR_KUBECTL create secret generic "keycloak-db-secret" \
      --from-literal=username="$(echo "$USERNAME" | base64 -d)" \
      --from-literal=password="$(echo "$PASSWORD" | base64 -d)" \
      -n "$KEYCLOAK_NAMESPACE"
    
    info "ensurePostgresSecret: created 'keycloak-db-secret' with database credentials"
  else
    debug "ensurePostgresSecret: 'keycloak-db-secret' already exists"
  fi
}

ensurePostgresDatabase() {
  POSTGRES_CLUSTER_NAME="vkdr-pg-cluster"
  POSTGRES_DB_NAME="keycloak"
  POSTGRES_USER="keycloak"
  POSTGRES_PASSWORD="auth1234"
  
  # Check if postgres cluster exists
  if ! $VKDR_KUBECTL get cluster "$POSTGRES_CLUSTER_NAME" -n "$DB_NAMESPACE" &>/dev/null; then
    boldInfo "Postgres cluster not found, installing postgres..."
    # Call postgres install command
    if command -v vkdr &>/dev/null; then
      vkdr postgres install --wait
    else
      error "ensurePostgresDatabase: vkdr command not found, cannot install postgres"
      exit 1
    fi
  else
    debug "ensurePostgresDatabase: postgres cluster '$POSTGRES_CLUSTER_NAME' already exists"
  fi
  
  # Check if kong database CRD exists
  if ! $VKDR_KUBECTL get database "${POSTGRES_CLUSTER_NAME}-${POSTGRES_DB_NAME}" -n "$DB_NAMESPACE" &>/dev/null; then
    boldInfo "Keycloak database not found, creating database..."
    # Call postgres createdb command
    if command -v vkdr &>/dev/null; then
      vkdr postgres createdb -d "$POSTGRES_DB_NAME" -u "$POSTGRES_USER" -p "$POSTGRES_PASSWORD"
    else
      error "ensurePostgresDatabase: vkdr command not found, cannot create database"
      exit 1
    fi
  else
    debug "ensurePostgresDatabase: kong database already exists"
  fi
  
  # Verify the role secret was created
  if ! $VKDR_KUBECTL get secret "${POSTGRES_CLUSTER_NAME}-role-${POSTGRES_USER}" -n "$DB_NAMESPACE" &>/dev/null; then
    error "ensurePostgresDatabase: expected secret '${POSTGRES_CLUSTER_NAME}-role-${POSTGRES_USER}' not found"
    exit 1
  fi
  
  boldInfo "Postgres database setup complete!"
}

#
# fix this in the future, focus on "spec.hostname.hostname" of CRD
# spec also has "spec.ingress.tls" or similar
#
configDomain() {
  VKDR_KEYCLOAK_PORT=""
    if [ "true" = "$VKDR_ENV_KEYCLOAK_SECURE" ]; then
      VKDR_PROTOCOL="https"
      if [ "$VKDR_HTTPS_PORT" != "443" ]; then
        VKDR_KEYCLOAK_PORT=":$VKDR_HTTPS_PORT"
      fi
    else
      VKDR_PROTOCOL="http"
      if [ "$VKDR_HTTP_PORT" != "80" ]; then
        VKDR_KEYCLOAK_PORT=":$VKDR_HTTP_PORT"
      fi
    fi
  # must set "spec.hostname.hostname" in $KEYCLOAK_FINAL_SERVER_YAML to 
  # $VKDR_PROTOCOL://auth.${VKDR_ENV_KEYCLOAK_DOMAIN}${VKDR_KEYCLOAK_PORT}
  FINAL_KEYCLOAK_HOSTNAME="$VKDR_PROTOCOL://auth.${VKDR_ENV_KEYCLOAK_DOMAIN}${VKDR_KEYCLOAK_PORT}"
  debug "configDomain: forcing hostname to '$FINAL_KEYCLOAK_HOSTNAME'"
  $VKDR_YQ eval ".spec.hostname.hostname = \"$FINAL_KEYCLOAK_HOSTNAME\"" -i $KEYCLOAK_FINAL_SERVER_YAML
  if [ "$VKDR_ENV_KEYCLOAK_SECURE" = "true" ]; then
    debug "configDomain: forcing HTTPS with ingress annotations"
    # forces https on Kong
    $VKDR_YQ -i ".spec.ingress.annotations.\"konghq.com/protocols\" = \"https\"" $VKDR_KEYCLOAK_VALUES
    $VKDR_YQ -i ".spec.ingress.annotations.\"konghq.com/https-redirect-status-code\" = \"301\"" $VKDR_KEYCLOAK_VALUES
    # should not enable TLS if using ACME plugin
    if detectACMEPlugin; then
      debug "configDomain: will not enable ingress TLS in $KEYCLOAK_FINAL_SERVER_YAML as ACME plugin is used"
      addHostToACMEIngress "auth.$VKDR_ENV_KEYCLOAK_DOMAIN"
    else
      debug "configDomain: setting keycloak ingress TLS in $KEYCLOAK_FINAL_SERVER_YAML"
      $VKDR_YQ eval ".spec.ingress.tlsSecret = \"keycloak-tls-secret\"" -i $KEYCLOAK_FINAL_SERVER_YAML
    fi
  fi
}

install() {
  debug "Keycloak install"
  $VKDR_KUBECTL apply -f "$KEYCLOAK_FINAL_SERVER_YAML" -n "$KEYCLOAK_NAMESPACE"
}

postInstall() {
  info "Keycloak install finished!"
}

createNamespace() {
  echo "
apiVersion: v1
kind: Namespace
metadata:
  name: $KEYCLOAK_NAMESPACE
" | $VKDR_KUBECTL apply -f -
}

runFormula
