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
VKDR_ENV_KONG_USE_NODEPORT=${11}
VKDR_ENV_KONG_ADMIN_OIDC=${12}
VKDR_ENV_KONG_LOG_LEVEL=${13}
VKDR_ENV_KONG_ENABLE_ACME=${14}
VKDR_ENV_KONG_ACME_SERVER=${15}
VKDR_ENV_KONG_ENV=${16}

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
  boldNotice "Admin GUI OIDC: $VKDR_ENV_KONG_ADMIN_OIDC"
  boldNotice "Log level: $VKDR_ENV_KONG_LOG_LEVEL"
  boldNotice "Enable ACME: $VKDR_ENV_KONG_ENABLE_ACME"
  boldNotice "ACME Server: $VKDR_ENV_KONG_ACME_SERVER"
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
  configUseNodePort
  configDefaultIngressController
  configAdminOIDC
  configLogLevel
  envKong
  installKong
  enableACME
  postInstallKong
}

enableACME() {
  if [ "$VKDR_ENV_KONG_ENABLE_ACME" != "true" ]; then
    return
  fi
  # deploy ACME plugin
  if [ "$VKDR_ENV_KONG_ACME_SERVER" = "staging" ]; then
    debug "enableACME: Deploying ACME global plugin (staging)..."
    $VKDR_KUBECTL apply -f "$(dirname "$0")/../../.util/values/acme-staging.yaml" -n "$KONG_NAMESPACE"
  elif [ "$VKDR_ENV_KONG_ACME_SERVER" = "production" ]; then
    debug "enableACME: Deploying ACME global plugin (production)..."
    $VKDR_KUBECTL apply -f "$(dirname "$0")/../../.util/values/acme-production.yaml" -n "$KONG_NAMESPACE"
  else
    debug "enableACME: Deploying ACME global plugin (custom server)..."
    error "TODO: Not implemented yet..."
  fi
  debug "enableACME: Deploying ACME ingress 'dummy-acme' fix..."
  cp "$(dirname "$0")/../../.util/values/acme-ingress-fix.yaml" /tmp/acme-ingress-fix.yaml
  sed -i.bak "s|host: manager.*|host: manager.$VKDR_ENV_KONG_DOMAIN|g" /tmp/acme-ingress-fix.yaml
  $VKDR_KUBECTL apply -f /tmp/acme-ingress-fix.yaml -n "$KONG_NAMESPACE"
}

settingKong() {
  case $VKDR_ENV_KONG_MODE in
    dbless)
      debug "Setting Kong to 'dbless' mode"
      VKDR_KONG_VALUES=/tmp/kong-dbless.yaml
      cp "$(dirname "$0")/../../.util/values/kong-dbless.yaml" $VKDR_KONG_VALUES
      if [ "$VKDR_ENV_KONG_ENTERPRISE" = "true" ]; then
        VKDR_KONG_ENT_VALUES="$(dirname "$0")/../../.util/values/delta-kong-enterprise.yaml"
        # merge yq files
        YAML_TMP_FILE=/tmp/kong-dbless-ent.yaml
        $VKDR_YQ eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$VKDR_KONG_VALUES" "$VKDR_KONG_ENT_VALUES" > "$YAML_TMP_FILE"
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
      cp "$(dirname "$0")/../../.util/values/kong-standard.yaml" $VKDR_KONG_VALUES
      if [ "$VKDR_ENV_KONG_ENTERPRISE" = "true" ]; then
        VKDR_KONG_ENT_VALUES="$(dirname "$0")/../../.util/values/delta-kong-enterprise.yaml"
        # merge yq files
        YAML_TMP_FILE=/tmp/kong-standard-ent.yaml
        $VKDR_YQ eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$VKDR_KONG_VALUES" "$VKDR_KONG_ENT_VALUES" > "$YAML_TMP_FILE"
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
        $VKDR_YQ eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$VKDR_KONG_VALUES" "$VKDR_KONG_SECRET_VALUES" > "$YAML_TMP_FILE_SECRET"
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

configAdminOIDC() {
  if [ "true" = "$VKDR_ENV_KONG_ADMIN_OIDC" ]; then
    debug "configAdminOIDC: configuring OIDC for Admin UI/API in $VKDR_KONG_VALUES"
    $VKDR_YQ eval '.enterprise.rbac.admin_gui_auth = "openid-connect"' -i $VKDR_KONG_VALUES
    $VKDR_YQ eval '.enterprise.rbac.admin_gui_auth_conf_secret = "kong-admin-oidc"' -i $VKDR_KONG_VALUES
    debug "configAdminOIDC: (re)creating 'kong-admin-oidc' secret for OIDC"
    # MUST become a one-liner
    $VKDR_JQ '.' -c "$(dirname "$0")/../../.util/values/admin_gui_auth_conf" > /tmp/admin_gui_auth_conf
    # fix domain and secure for "http://auth.localhost" and "http://manager.localhost" references
    debug "configAdminOIDC: fixing 'http://auth.localhost' and 'http://manager.localhost' references in /tmp/admin_gui_auth_conf"
    VKDR_PROTOCOL="http"
    if [ "true" = "$VKDR_ENV_KONG_SECURE" ]; then
      VKDR_PROTOCOL="https"
      $VKDR_JQ '.session_cookie_secure = true' /tmp/admin_gui_auth_conf > /tmp/admin_gui_auth_conf.tmp
      mv /tmp/admin_gui_auth_conf.tmp /tmp/admin_gui_auth_conf
    fi
    MANAGER_URL="$VKDR_PROTOCOL://manager.$VKDR_ENV_KONG_DOMAIN"
    AUTH_URL="$VKDR_PROTOCOL://auth.$VKDR_ENV_KONG_DOMAIN"
    sed -i.bak1 's|http://auth.localhost|'"$AUTH_URL"'|g' /tmp/admin_gui_auth_conf
    sed -i.bak2 's|http://manager.localhost|'"$MANAGER_URL"'|g' /tmp/admin_gui_auth_conf

    $VKDR_KUBECTL delete secret kong-admin-oidc -n $KONG_NAMESPACE
    $VKDR_KUBECTL create secret generic kong-admin-oidc "--from-file=/tmp/admin_gui_auth_conf" -n $KONG_NAMESPACE
  fi
}

configLogLevel() {
  $VKDR_YQ eval ".env.log_level = \"$VKDR_ENV_KONG_LOG_LEVEL\"" -i $VKDR_KONG_VALUES
}

configDefaultIngressController() {
  if [ "true" = "$VKDR_ENV_KONG_DEFAULT_INGRESS_CONTROLLER" ]; then
    debug "configDefaultIngressController: configuring Kong as default ingress controller in $VKDR_KONG_VALUES"
    $VKDR_YQ eval '.ingressController.ingressClassAnnotations += { "ingressclass.kubernetes.io/is-default-class": "true" }' -i $VKDR_KONG_VALUES
  fi  
}

configUseNodePort() {
  if [ "true" = "$VKDR_ENV_KONG_USE_NODEPORT" ]; then
    debug "configUseNodePort: configuring Kong to use NodePort instead of LoadBalancer in $VKDR_KONG_VALUES"
    $VKDR_YQ eval '.proxy.type = "NodePort"' -i $VKDR_KONG_VALUES
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
    #$VKDR_YQ -i ".proxy.tls.overrideServiceTargetPort = 80" $VKDR_KONG_VALUES
    if [ "$VKDR_PROTOCOL" = "https" ] && [ "$VKDR_ENV_KONG_DOMAIN" != "localhost" ]; then
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
      debug "configDomain: forcing https for manager/admin in $VKDR_KONG_VALUES"
      $VKDR_YQ -i ".manager.ingress.annotations.\"konghq.com/protocols\" = \"https\"" $VKDR_KONG_VALUES
      $VKDR_YQ -i ".manager.ingress.annotations.\"konghq.com/https-redirect-status-code\" = \"301\"" $VKDR_KONG_VALUES
      $VKDR_YQ -i ".admin.ingress.annotations.\"konghq.com/https-redirect-status-code\" = \"301\"" $VKDR_KONG_VALUES
      $VKDR_YQ -i ".admin.ingress.annotations.\"konghq.com/protocols\" = \"https\"" $VKDR_KONG_VALUES
      # no TLS if using ACME plugin
      if [ "$VKDR_ENV_KONG_ENABLE_ACME" != "true" ]; then
        $VKDR_YQ -i ".manager.ingress.tls = \"kong-admin-tls\"" $VKDR_KONG_VALUES
        $VKDR_YQ -i ".admin.ingress.tls = \"kong-admin-tls\"" $VKDR_KONG_VALUES
      fi
    fi
  else
    debug "configDomain: using manager default 'localhost' domain in $VKDR_KONG_VALUES"
  fi
}

envKong() {
  # convert JSON to YAML under "env:"
  debug "envKong: merging kong env '$VKDR_ENV_KONG_ENV'"
  echo "$VKDR_ENV_KONG_ENV" | $VKDR_YQ -p=json -o=yaml > /tmp/kong-env-vars.yaml
  $VKDR_YQ eval '.env *= load("/tmp/kong-env-vars.yaml")' -i "$VKDR_KONG_VALUES"
}

installKong() {
  debug "installKong: add/update helm repo"
  $VKDR_HELM repo add kong https://charts.konghq.com
  $VKDR_HELM repo update
  debug "installKong: installing kong"
  $VKDR_HELM upgrade -i kong kong/kong -n $KONG_NAMESPACE --values $VKDR_KONG_VALUES
}

postInstallKong() {
  # patching very very very special case, must check later
  if [ "$VKDR_ENV_KONG_API_INGRESS" = "true" ]; then
    debug "postInstallKong: patching ingress for special case (careful, not sure here)"
    $VKDR_KUBECTL patch ingress -n $KONG_NAMESPACE kong-kong-proxy \
      --type='json' -p='[{"op": "replace", "path": "/spec/rules/0/http/paths/0/backend/service/port/number", "value": 80}]'
  fi
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
  debug "Creating kong-session-config secret from random value..."
  ADMIN_COOKIE_SECRET=$(head -c 64 /dev/urandom | LC_CTYPE=C tr -dc 'a-zA-Z0-9!@#$%^&*()_+-=[]{}|;:,.<>?' | head -c 16)
  ADMIN_COOKIE_SECURE=${VKDR_ENV_KONG_SECURE:-false}
  echo '{"cookie_name":"admin_session","cookie_samesite":"Strict","secret":"'"$ADMIN_COOKIE_SECRET"'","cookie_secure":'"$ADMIN_COOKIE_SECURE"',"storage":"kong"}' > /tmp/admin_gui_session_conf
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
