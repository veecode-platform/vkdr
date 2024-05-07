#!/usr/bin/env bash

VKDR_ENV_KONG_DOMAIN=$1
VKDR_ENV_KONG_SECURE=$2
VKDR_ENV_KONG_MODE=$3
VKDR_ENV_KONG_ENTERPRISE=$4
VKDR_ENV_KONG_LICENSE=$5
VKDR_ENV_KONG_IMAGE_NAME=$6
VKDR_ENV_KONG_IMAGE_TAG=$7
VKDR_ENV_KONG_PASSWORD=$8
VKDR_ENV_KONG_API_INGRESS=$9
VKDR_ENV_KONG_DEFAULT_INGRESS_CONTROLLER=${10}
VKDR_ENV_KONG_ENV=${11}

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

KONG_NAMESPACE=vkdr

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
  boldNotice "Admin password: $VKDR_ENV_KONG_PASSWORD"
  boldNotice "API Ingress: $VKDR_ENV_KONG_API_INGRESS"
  boldNotice "Default Ingress Controller: $VKDR_ENV_KONG_DEFAULT_INGRESS_CONTROLLER"
  boldNotice "Environment: $VKDR_ENV_KONG_ENV"
  bold "=============================="
}

runFormula() {
  startInfos
  settingKong
  createKongNamespace
  createKongLicenseSecret
  createKongAdminSecret
  createKongSessionConfigSecret
  configDomain
  configApiDomain
  configDefaultIngressController
  envKong
  installKong
  postInstallKong
}

settingKong() {
  case $VKDR_ENV_KONG_MODE in
    dbless)
      debug "Setting Kong to 'dbless' mode"
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
      debug "Setting Kong to 'standard' mode"
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
      # if there is a "kong-pg-secret", use those credentials and do not install postgres subchart
      if $VKDR_KUBECTL get secrets -n $KONG_NAMESPACE | grep -q "kong-pg-secret" ; then
        VKDR_KONG_SECRET_VALUES="$(dirname "$0")"/../../.util/values/delta-kong-std-dbsecrets.yaml
        YAML_TMP_FILE_SECRET=/tmp/kong-secret-std.yaml
        $VKDR_YQ eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' $VKDR_KONG_VALUES $VKDR_KONG_SECRET_VALUES > $YAML_TMP_FILE_SECRET
        VKDR_KONG_VALUES=$YAML_TMP_FILE_SECRET
      fi
      ;;
    hybrid)
      error "hybrid not yet implemented"
      exit 1
      ;;
    *)
      error "Mode '$VKDR_ENV_KONG_MODE' is invalid! Aborting."
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
    debug "Kong values file is $VKDR_KONG_VALUES"
    #FILE_DUMP="$(cat $VKDR_KONG_VALUES)"
    #debug $FILE_DUMP
}

configDefaultIngressController() {
  if [ "true" = "$VKDR_ENV_KONG_DEFAULT_INGRESS_CONTROLLER" ]; then
    debug "configDefaultIngressController: configuring Kong as default ingress controller in $VKDR_KONG_VALUES"
    $VKDR_YQ eval '.ingressController.ingressClassAnnotations += { "ingressclass.kubernetes.io/is-default-class": "true" }' -i $VKDR_KONG_VALUES
  fi  
}

configApiDomain() {
  # change domain under VKDR_KONG_VALUES
  # - proxy.ingress.enabled
  # - proxy.ingress.hostname
  # - proxy.ingress.tls
  VKDR_PROTOCOL="http"
  if [ "true" = "$VKDR_ENV_KONG_SECURE" ]; then
    VKDR_PROTOCOL="https"
  fi
  if [ "$VKDR_ENV_KONG_API_INGRESS" = "true" ]; then
    debug "configApiDomain: setting gateway domain to 'api.$VKDR_ENV_KONG_DOMAIN' in $VKDR_KONG_VALUES"
    $VKDR_YQ -i ".proxy.ingress.enabled = \"true\"" $VKDR_KONG_VALUES
    $VKDR_YQ -i ".proxy.ingress.hostname = \"api.$VKDR_ENV_KONG_DOMAIN\"" $VKDR_KONG_VALUES
    if [ "$VKDR_PROTOCOL" = "https" ]; then
      debug "configApiDomain: setting gateway TLS in $VKDR_KONG_VALUES"
      $VKDR_YQ -i ".proxy.ingress.tls = \"kong-api-tls\"" $VKDR_KONG_VALUES
    fi
  else
    debug "configApiDomain: not using gateway API ingress, skipping domain change"
  fi
}

configDomain() {
  # change domain under VKDR_KONG_VALUES
  # - manager.ingress.hostname
  # - admin.ingress.hostname
  # - env.admin_gui_url
  # - env.admin_gui_api_url
  VKDR_PROTOCOL="http"
  if [ "true" = "$VKDR_ENV_KONG_SECURE" ]; then
    VKDR_PROTOCOL="https"
  fi
  if [ "$VKDR_ENV_KONG_DOMAIN" != "localhost" ]; then
    debug "configDomain: setting manager domain to $VKDR_ENV_KONG_DOMAIN in $VKDR_KONG_VALUES"
    $VKDR_YQ -i ".manager.ingress.hostname = \"manager.$VKDR_ENV_KONG_DOMAIN\"" $VKDR_KONG_VALUES
    $VKDR_YQ -i ".admin.ingress.hostname = \"manager.$VKDR_ENV_KONG_DOMAIN\"" $VKDR_KONG_VALUES
    $VKDR_YQ -i ".env.admin_gui_url = \"$VKDR_PROTOCOL://manager.$VKDR_ENV_KONG_DOMAIN/manager\"" $VKDR_KONG_VALUES
    $VKDR_YQ -i ".env.admin_gui_api_url = \"$VKDR_PROTOCOL://manager.$VKDR_ENV_KONG_DOMAIN\"" $VKDR_KONG_VALUES
    if [ "$VKDR_PROTOCOL" = "https" ]; then
      debug "configDomain: setting manager TLS in $VKDR_KONG_VALUES"
      $VKDR_YQ -i ".manager.ingress.tls = \"kong-admin-tls\"" $VKDR_KONG_VALUES
      $VKDR_YQ -i ".admin.ingress.tls = \"kong-admin-tls\"" $VKDR_KONG_VALUES
    fi
  else
    debug "configDomain: using manager default 'localhost' domain in $VKDR_KONG_VALUES"
  fi
}

envKong() {
  # convert JSON to YAML under "env:"
  debug "envKong: merging kong env '$VKDR_ENV_KONG_ENV'"
  echo $VKDR_ENV_KONG_ENV | $VKDR_YQ -p=json -o=yaml > /tmp/kong-env-vars.yaml
  $VKDR_YQ eval '.env *= load("/tmp/kong-env-vars.yaml")' -i $VKDR_KONG_VALUES
}

installKong() {
  debug "installKong: add/update helm repo"
  $VKDR_HELM repo add kong https://charts.konghq.com
  $VKDR_HELM repo update
  debug "installKong: installing kong"
  $VKDR_HELM upgrade -i kong kong/kong -n $KONG_NAMESPACE --values $VKDR_KONG_VALUES
}

postInstallKong() {
  info "Kong install finished!"
}

createKongSessionConfigSecret() {
  if [ "$VKDR_ENV_KONG_ENTERPRISE" = "false" ]; then
    debug "Kong enterprise was not selected, skipping session config secret creation..."
    return
  fi
  if $VKDR_KUBECTL get secrets -n $KONG_NAMESPACE | grep -q "kong-session-config" ; then
    debug "Kong enterprise session config secret already exists, skipping..."
    return
  fi
  debug "Creating kong-session-config secret from random value (requires 'pwgen')..."
  ADMIN_COOKIE_SECRET=$(pwgen 15 1)
  echo '{"cookie_name":"admin_session","cookie_samesite":"Strict","secret":"'$ADMIN_COOKIE_SECRET'","cookie_secure":false,"storage":"kong"}' > /tmp/admin_gui_session_conf
  $VKDR_KUBECTL create secret generic kong-session-config -n $KONG_NAMESPACE --from-file=admin_gui_session_conf=/tmp/admin_gui_session_conf

  RESULT=$?
  debug "Create Kong enterprise license secret status = $RESULT"  
}

createKongLicenseSecret() {
  if [ "$VKDR_ENV_KONG_ENTERPRISE" = "false" ]; then
    debug "Kong enterprise was not selected, skipping license secret creation..."
    return
  fi
  if $VKDR_KUBECTL get secrets -n $KONG_NAMESPACE | grep -q "kong-enterprise-license" ; then
    debug "Kong enterprise license secret already exists, skipping..."
    return
  fi
  if [ -f "$VKDR_ENV_KONG_LICENSE" ]; then
    debug "Creating kong-enterprise-license secret from '$VKDR_ENV_KONG_LICENSE'..."
    $VKDR_KUBECTL create secret generic kong-enterprise-license -n $KONG_NAMESPACE --from-file=license="$VKDR_ENV_KONG_LICENSE"
  else
    debug "Creating empty kong-enterprise-license secret..."
    $VKDR_KUBECTL create secret generic kong-enterprise-license -n $KONG_NAMESPACE --from-literal=license=""
  fi

  RESULT=$?
  debug "Create Kong enterprise license secret status = $RESULT"
}

createKongAdminSecret() {
  if [ "$VKDR_ENV_KONG_ENTERPRISE" = "false" ]; then
    debug "Kong enterprise was not selected, skipping admin secret creation..."
    return
  fi
  if $VKDR_KUBECTL get secrets -n $KONG_NAMESPACE | grep -q "kong-enterprise-superuser-password" ; then
    debug "Kong enterprise admin secret already exists, skipping..."
    return
  fi
  if [ -n "$VKDR_ENV_KONG_PASSWORD" ]; then
    debug "Creating kong-enterprise-superuser-password secret from '$VKDR_ENV_KONG_PASSWORD'..."
    $VKDR_KUBECTL create secret generic kong-enterprise-superuser-password -n $KONG_NAMESPACE --from-literal=password="$VKDR_ENV_KONG_PASSWORD"
  else
    debug "Creating random kong-enterprise-superuser-password secret (requires 'pwgen')..."
    $VKDR_KUBECTL create secret generic kong-enterprise-superuser-password -n $KONG_NAMESPACE --from-literal=password="$(pwgen 15 -1)"
  fi

  RESULT=$?
  debug "Create Kong enterprise admin secret status = $RESULT"
}

createKongNamespace() {
  debug "Create Kong namespace '$KONG_NAMESPACE'"
  echo "
apiVersion: v1
kind: Namespace
metadata:
  name: $KONG_NAMESPACE
" | $VKDR_KUBECTL apply -f -
}

runFormula
