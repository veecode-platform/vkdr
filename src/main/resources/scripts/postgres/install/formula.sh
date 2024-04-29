#!/usr/bin/env bash

VKDR_ENV_POSTGRES_ADMIN_PASSWORD=$1

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

POSTGRES_NAMESPACE=vkdr

startInfos() {
  boldInfo "Postgres Install"
  bold "=============================="
  boldNotice "Admin password: $VKDR_ENV_POSTGRES_ADMIN_PASSWORD"
  #boldNotice "Secure: $VKDR_ENV_KEYCLOAK_SECURE"
  bold "=============================="
  infoYellow "Please understand that password arguments are ignored if database already exists."
}

runFormula() {
  startInfos
  createNamespace
  install
  postInstall
}


install() {
  debug "install: installing Postgres"
  helm install postgres oci://registry-1.docker.io/bitnamicharts/postgresql \
    -n "$POSTGRES_NAMESPACE" \
    --set "auth.postgresPassword=$VKDR_ENV_POSTGRES_ADMIN_PASSWORD"
  #helm upgrade -i postgres kong/kong -n $POSTGRES_NAMESPACE \
  #  --set "auth.postgresPassword=$VKDR_ENV_POSTGRES_ADMIN_PASSWORD"
}

postInstall() {
  info "Postgres install finished!"
}

createNamespace() {
  echo "
apiVersion: v1
kind: Namespace
metadata:
  name: $POSTGRES_NAMESPACE
" | kubectl apply -f -
}

runFormula
