#!/usr/bin/env bash

VKDR_ENV_KONG_DOMAIN=$1
VKDR_ENV_KONG_SECURE=$2
VKDR_ENV_KONG_MODE=$3
VKDR_ENV_KONG_ENTERPRISE=$4
VKDR_ENV_KONG_LICENSE=$5

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

KONG_NAMESPACE=kong

startInfos() {
  boldInfo "Kong Install"
  bold "=============================="
  boldNotice "Domain: $VKDR_ENV_KONG_DOMAIN"
  boldNotice "Secure: $VKDR_ENV_KONG_SECURE"
  boldNotice "Mode: $VKDR_ENV_KONG_MODE"
  boldNotice "Enterprise: $VKDR_ENV_KONG_ENTERPRISE"
  boldNotice "License file: $VKDR_ENV_KONG_LICENSE"
  bold "=============================="
}

runFormula() {
  startInfos
  settingKong
  createKongNamespace
  createKongLicenseSecret
  installKong
  postInstallKong
}

settingKong() {
  case $VKDR_ENV_KONG_MODE in
    dbless)
      VKDR_KONG_VALUES="$(dirname "$0")"/../../.util/values/kong-dbless.yaml
      if [ "$VKDR_ENV_KONG_ENTERPRISE" = "true" ]; then
        VKDR_KONG_ENT_VALUES="$(dirname "$0")"/../../.util/values/delta-kong-enterprise.yaml
        # merge yq files
        $VKDR_YQ eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' $VKDR_KONG_VALUES $VKDR_KONG_ENT_VALUES > /tmp/kong-dbless-ent.yaml
        VKDR_KONG_VALUES=/tmp/kong-dbless-ent.yaml
      fi
      ;;
    standard)
      error "standard not yet implemented"
      exit 1
      ;;
    hybrid)
      error "hybrid not yet implemented"
      exit 1
      ;;
    esac
}

installKong() {
  debug "installKong: add/update helm repo"
  helm repo add kong https://charts.konghq.com
  helm repo update
  debug "installKong: installing kong"
  helm upgrade -i kong kong/kong -n $KONG_NAMESPACE --values $VKDR_KONG_VALUES
}

postInstallKong() {
  info "Kong install finished!"
}

createKongLicenseSecret() {
  if [ "$VKDR_ENV_KONG_ENTERPRISE" = "false" ]; then
    debug "Kong enterprise was not selected, skipping secret creation..."
    return
  fi
  if kubectl get secrets -n $KONG_NAMESPACE | grep -q "kong-enterprise-license" ; then
    debug "Kong enterprise license secret already exists, skipping..."
    return
  fi
  if [ -f "$VKDR_ENV_KONG_LICENSE" ]; then
    info "Creating kong-enterprise-license secret from '$VKDR_ENV_KONG_LICENSE'..."
    $VKDR_KUBECTL create secret generic kong-enterprise-license -n $KONG_NAMESPACE --from-file=license="$VKDR_ENV_KONG_LICENSE"
  else
    info "Creating empty kong-enterprise-license secret..."
    $VKDR_KUBECTL create secret generic kong-enterprise-license -n $KONG_NAMESPACE --from-literal=license=""
  fi

  RESULT=$?
  debug "Create Kong enterprise secret status = $RESULT"
}

createKongNamespace() {
  echo "
apiVersion: v1
kind: Namespace
metadata:
  name: $KONG_NAMESPACE
" | kubectl apply -f -
}

runFormula
