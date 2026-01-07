#!/usr/bin/env bash

VKDR_ENV_MINIO_DOMAIN=$1
VKDR_ENV_MINIO_SECURE=$2
VKDR_ENV_MINIO_PASSWORD=$3
VKDR_ENV_MINIO_API_INGRESS=$4

# V2 paths: relative to formulas/minio/install/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

MINIO_NAMESPACE=vkdr

startInfos() {
  boldInfo "Minio Install"
  bold "=============================="
  boldNotice "Domain: $VKDR_ENV_MINIO_DOMAIN"
  boldNotice "Secure: $VKDR_ENV_MINIO_SECURE"
  boldNotice "Admin password: $VKDR_ENV_MINIO_PASSWORD"
  boldNotice "Enable API Ingress: $VKDR_ENV_MINIO_API_INGRESS"
  bold "=============================="
}

runFormula() {
  startInfos
  settingMinio
  createMinioNamespace
  configDomain
  configApiDomain
  installMinio
}

settingMinio() {
  debug "settingMinio: obtaining default Minio settings"
  VKDR_MINIO_VALUES=/tmp/minio-standalone.yaml
  cp "$SHARED_DIR/values/minio-standalone.yaml" $VKDR_MINIO_VALUES
  $VKDR_YQ -i ".auth.rootPassword = \"$VKDR_ENV_MINIO_PASSWORD\"" $VKDR_MINIO_VALUES
}

configApiDomain() {
  if [ "$VKDR_ENV_MINIO_API_INGRESS" != "true" ]; then
    debug "configApiDomain: Minio API ingress is disabled, skipping..."
    return
  fi
  debug "configApiDomain: setting Minio api domain to $VKDR_ENV_MINIO_DOMAIN in $VKDR_MINIO_VALUES"
  $VKDR_YQ -i ".apiIngress.hostname = \"minio-api.${VKDR_ENV_MINIO_DOMAIN}\"" $VKDR_MINIO_VALUES
  if [ "$VKDR_ENV_MINIO_SECURE" = "true" ]; then
    debug "configDomain: forcing https for Minio console in $VKDR_MINIO_VALUES"
    $VKDR_YQ -i ".apiIngress.annotations.\"konghq.com/protocols\" = \"https\"" $VKDR_MINIO_VALUES
    $VKDR_YQ -i ".apiIngress.annotations.\"konghq.com/https-redirect-status-code\" = \"301\"" $VKDR_MINIO_VALUES
    $VKDR_YQ -i ".apiIngress.annotations.\"konghq.com/https-redirect-status-code\" = \"301\"" $VKDR_MINIO_VALUES
    $VKDR_YQ -i ".apiIngress.annotations.\"konghq.com/protocols\" = \"https\"" $VKDR_MINIO_VALUES
    # no TLS if using ACME plugin under kong
    #if [ "$VKDR_ENV_KONG_ENABLE_ACME" != "true" ]; then
    $VKDR_YQ -i ".apiIngress.tls = true" $VKDR_MINIO_VALUES
    $VKDR_YQ -i ".apiIngress.selfSigned = true" $VKDR_MINIO_VALUES
    #fi
  fi
}

configDomain() {
  debug "configDomain: setting Minio console domain to $VKDR_ENV_MINIO_DOMAIN in $VKDR_MINIO_VALUES"
  $VKDR_YQ -i ".ingress.hostname = \"minio.$VKDR_ENV_MINIO_DOMAIN\"" $VKDR_MINIO_VALUES
  if [ "$VKDR_ENV_MINIO_SECURE" = "true" ]; then
    debug "configDomain: forcing https for Minio console in $VKDR_MINIO_VALUES"
    $VKDR_YQ -i ".ingress.annotations.\"konghq.com/protocols\" = \"https\"" $VKDR_MINIO_VALUES
    $VKDR_YQ -i ".ingress.annotations.\"konghq.com/https-redirect-status-code\" = \"301\"" $VKDR_MINIO_VALUES
    $VKDR_YQ -i ".ingress.annotations.\"konghq.com/https-redirect-status-code\" = \"301\"" $VKDR_MINIO_VALUES
    $VKDR_YQ -i ".ingress.annotations.\"konghq.com/protocols\" = \"https\"" $VKDR_MINIO_VALUES
    # no TLS if using ACME plugin under kong
    #if [ "$VKDR_ENV_KONG_ENABLE_ACME" != "true" ]; then
    $VKDR_YQ -i ".ingress.tls = true" $VKDR_MINIO_VALUES
    $VKDR_YQ -i ".ingress.selfSigned = true" $VKDR_MINIO_VALUES
    #fi
  fi
}

installMinio() {
  #debug "installMinio: add/update helm repo"
  #$VKDR_HELM repo add minio oci://registry-1.docker.io/bitnamicharts/minio
  #$VKDR_HELM repo update minio
  debug "installMinio: installing Minio storage"
  $VKDR_HELM upgrade -i minio oci://registry-1.docker.io/bitnamicharts/minio -n $MINIO_NAMESPACE --values $VKDR_MINIO_VALUES
}

createMinioNamespace() {
  debug "Create Minio namespace '$MINIO_NAMESPACE'"
  echo "
apiVersion: v1
kind: Namespace
metadata:
  name: $MINIO_NAMESPACE
" | $VKDR_KUBECTL apply -f -
}

runFormula
