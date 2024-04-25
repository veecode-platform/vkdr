#!/usr/bin/env bash

VKDR_ENV_KONG_DOMAIN=$1
VKDR_ENV_KONG_SECURE=$2
VKDR_ENV_KONG_MODE=$3
VKDR_ENV_KONG_ENTERPRISE=$4
VKDR_ENV_KONG_LICENSE=$5
VKDR_ENV_KONG_IMAGE_NAME=$6
VKDR_ENV_KONG_IMAGE_TAG=$7
VKDR_ENV_KONG_ENV=$8

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
  boldNotice "Image name: $VKDR_ENV_KONG_IMAGE_NAME"
  boldNotice "Image tag: $VKDR_ENV_KONG_IMAGE_TAG"
  boldNotice "Environment: $VKDR_ENV_KONG_ENV"
  bold "=============================="
}

runFormula() {
  startInfos
  settingKong
  createKongNamespace
  createKongLicenseSecret
  envKong
  installKong
  postInstallKong
}

settingKong() {
  case $VKDR_ENV_KONG_MODE in
    dbless)
      VKDR_KONG_VALUES=/tmp/kong-dbless.yaml
      cp "$(dirname "$0")"/../../.util/values/kong-dbless.yaml $VKDR_KONG_VALUES
      if [ "$VKDR_ENV_KONG_ENTERPRISE" = "true" ]; then
        VKDR_KONG_ENT_VALUES="$(dirname "$0")"/../../.util/values/delta-kong-enterprise.yaml
        # merge yq files
        YAML_TMP_FILE=/tmp/kong-dbless-ent.yaml
        $VKDR_YQ eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' $VKDR_KONG_VALUES $VKDR_KONG_ENT_VALUES > $YAML_TMP_FILE
        VKDR_KONG_VALUES=$YAML_TMP_FILE
        # forces enterprise image if not set
        if [ -z "$VKDR_ENV_KONG_IMAGE_NAME" ]; then
          VKDR_ENV_KONG_IMAGE_NAME="kong/kong-gateway"
        fi
      fi
      ;;
    standard)
      VKDR_KONG_VALUES=/tmp/kong-standard.yaml
      cp "$(dirname "$0")"/../../.util/values/kong-standard.yaml $VKDR_KONG_VALUES
      if [ "$VKDR_ENV_KONG_ENTERPRISE" = "true" ]; then
        VKDR_KONG_ENT_VALUES="$(dirname "$0")"/../../.util/values/delta-kong-enterprise.yaml
        # merge yq files
        YAML_TMP_FILE=/tmp/kong-standard-ent.yaml
        $VKDR_YQ eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' $VKDR_KONG_VALUES $VKDR_KONG_ENT_VALUES > $YAML_TMP_FILE
        VKDR_KONG_VALUES=$YAML_TMP_FILE
        # forces enterprise image if not set
        if [ -z "$VKDR_ENV_KONG_IMAGE_NAME" ]; then
          VKDR_ENV_KONG_IMAGE_NAME="kong/kong-gateway"
        fi
      fi
      ;;
    hybrid)
      error "hybrid not yet implemented"
      exit 1
      ;;
    esac
    # change image name/tag if set
    if [ -n "$VKDR_ENV_KONG_IMAGE_NAME" ]; then
      $VKDR_YQ eval ".image.repository = \"$VKDR_ENV_KONG_IMAGE_NAME\"" -i $VKDR_KONG_VALUES
    fi
    if [ -n "$VKDR_ENV_KONG_IMAGE_TAG" ]; then
      $VKDR_YQ eval ".image.tag = \"$VKDR_ENV_KONG_IMAGE_TAG\"" -i $VKDR_KONG_VALUES
    fi
}

envKong() {
  # convert JSON to YAML under "env:"
  debug "envKong: merging kong env"
  echo $VKDR_ENV_KONG_ENV | yq -p=json > /tmp/kong-env-vars.yaml
  yq eval '.env *= load("/tmp/kong-env-vars.yaml")' -i $VKDR_KONG_VALUES
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
