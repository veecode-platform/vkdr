#!/usr/bin/env bash

VKDR_ENV_KEYCLOAK_DOMAIN=$1
VKDR_ENV_KEYCLOAK_SECURE=$2
VKDR_ENV_KEYCLOAK_ADMIN_USER=$3
VKDR_ENV_KEYCLOAK_ADMIN_PASSWORD=$4

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"
source "$(dirname "$0")/../../.util/ingress-tools.sh"

KEYCLOAK_NAMESPACE=vkdr
# port values override by detectClusterPorts
VKDR_HTTP_PORT=8000
VKDR_HTTPS_PORT=8001

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
  configure
  configDomain
  createNamespace
  install
  postInstall
}

configure() {
  VKDR_KEYCLOAK_VALUES=/tmp/keycloak-standard.yaml
  cp "$(dirname "$0")"/../../.util/values/keycloak-standard.yaml $VKDR_KEYCLOAK_VALUES
  # set domain to "auth.DOMAIN"

  # if there is a "keycloak-pg-secret" use those credentials and do not install postgres subchart
  if $VKDR_KUBECTL get secrets -n $KEYCLOAK_NAMESPACE | grep -q "keycloak-pg-secret" ; then
    VKDR_KEYCLOAK_SECRET_VALUES="$(dirname "$0")"/../../.util/values/delta-keycloak-std-dbsecrets.yaml
    YAML_TMP_FILE_SECRET=/tmp/keycloak-secret-std.yaml
    $VKDR_YQ eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' $VKDR_KEYCLOAK_VALUES $VKDR_KEYCLOAK_SECRET_VALUES > $YAML_TMP_FILE_SECRET
    VKDR_KEYCLOAK_VALUES=$YAML_TMP_FILE_SECRET
  fi
}

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
  if [ "$VKDR_ENV_KEYCLOAK_DOMAIN" != "localhost" ]; then
    debug "configDomain: setting keycloak hostname to 'auth.$VKDR_ENV_KEYCLOAK_DOMAIN' in $VKDR_KEYCLOAK_VALUES"
    $VKDR_YQ eval ".ingress.hostname = \"auth.$VKDR_ENV_KEYCLOAK_DOMAIN\"" -i $VKDR_KEYCLOAK_VALUES
  fi
  if [ "$VKDR_ENV_KEYCLOAK_SECURE" = "true" ]; then
    debug "configDomain: forcing HTTPS with ingress annotations"
    # forces https on Kong
    $VKDR_YQ -i ".ingress.annotations.\"konghq.com/protocols\" = \"https\"" $VKDR_KEYCLOAK_VALUES
    $VKDR_YQ -i ".ingress.annotations.\"konghq.com/https-redirect-status-code\" = \"301\"" $VKDR_KEYCLOAK_VALUES
    # should not enable TLS if using ACME plugin
    if detectACMEPlugin; then
      debug "configDomain: will not enable ingress TLS in $VKDR_KEYCLOAK_VALUES as ACME plugin is used"
      addHostToACMEIngress "auth.$VKDR_ENV_KEYCLOAK_DOMAIN"
    else
      debug "configDomain: setting keycloak ingress TLS in $VKDR_KEYCLOAK_VALUES"
      $VKDR_YQ eval ".ingress.tls = true" -i $VKDR_KEYCLOAK_VALUES
    fi
  fi
  export NEW_HOSTNAME="$VKDR_PROTOCOL://auth.${VKDR_ENV_KEYCLOAK_DOMAIN}${VKDR_KEYCLOAK_PORT}"
  debug "configDomain: fixing KC_HOSTNAME_URL to $NEW_HOSTNAME"
  $VKDR_YQ e '( .extraEnvVars[] | select(.name == "KC_HOSTNAME_URL") ).value = env(NEW_HOSTNAME)' -i $VKDR_KEYCLOAK_VALUES
}

install() {
  debug "Keycloak install: add/update helm repo"
  $VKDR_HELM repo add bitnami https://charts.bitnami.com/bitnami
  $VKDR_HELM repo update bitnami
  debug "install: installing Keycloak"
  $VKDR_HELM upgrade -i keycloak bitnami/keycloak \
    -n $KEYCLOAK_NAMESPACE --version 21.2.1 --values $VKDR_KEYCLOAK_VALUES
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
