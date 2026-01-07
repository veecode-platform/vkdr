#!/usr/bin/env bash

VKDR_ENV_DEVPORTAL_DOMAIN=$1
VKDR_ENV_DEVPORTAL_SECURE=$2
VKDR_ENV_DEVPORTAL_GITHUB_TOKEN=$3
VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_ID=$4
VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_SECRET=$5
VKDR_ENV_DEVPORTAL_GITHUB_AUTH_CLIENT_ID=$6
VKDR_ENV_DEVPORTAL_GITHUB_AUTH_CLIENT_SECRET=$7
VKDR_ENV_DEVPORTAL_GITHUB_APP_ID=$8
VKDR_ENV_DEVPORTAL_GITHUB_ORG=$9
VKDR_ENV_DEVPORTAL_GITHUB_PRIVATE_KEY_BASE64=${10}
VKDR_ENV_DEVPORTAL_INSTALL_SAMPLES=${11}
VKDR_ENV_DEVPORTAL_CATALOG_LOCATION=${12}
VKDR_ENV_DEVPORTAL_NPM_REGISTRY=${13}
VKDR_ENV_DEVPORTAL_MERGE_VALUES=${14}
VKDR_ENV_DEVPORTAL_PROFILE=${15}
VKDR_ENV_DEVPORTAL_LOAD_ENV=${16}

# V2 paths: relative to formulas/devportal/install/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"
source "$SHARED_DIR/lib/ingress-tools.sh"
source "$SHARED_DIR/lib/docker-tools.sh"
#source "$SHARED_DIR/devportal-k8s-service-account/generateSAToken.sh"

VKDR_DEVPORTAL_VALUES_SRC="$SHARED_DIR/values/devportal-common.yaml"
VKDR_DEVPORTAL_VALUES="/tmp/devportal.yaml"
VKDR_DEVPORTAL_GITHUB_PRIVATE_KEY=""

# port values override by detectClusterPorts
VKDR_HTTP_PORT=8000
VKDR_HTTPS_PORT=8001

# nao eh vkdr, eh platform
DEVPORTAL_NAMESPACE=platform

prepareGitHubEnv() {
  # if auth client vars not provided, fallback to regular client vars
  if [ -z "$VKDR_ENV_DEVPORTAL_GITHUB_AUTH_CLIENT_ID" ]; then
    VKDR_ENV_DEVPORTAL_GITHUB_AUTH_CLIENT_ID="$VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_ID"
    debug "prepareGitHubEnv: GITHUB_AUTH_CLIENT_ID not provided, using GITHUB_CLIENT_ID for auth"
  fi
  if [ -z "$VKDR_ENV_DEVPORTAL_GITHUB_AUTH_CLIENT_SECRET" ]; then
    VKDR_ENV_DEVPORTAL_GITHUB_AUTH_CLIENT_SECRET="$VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_SECRET"
    debug "prepareGitHubEnv: GITHUB_AUTH_CLIENT_SECRET not provided, using GITHUB_CLIENT_SECRET for auth"
  fi
  # read pk from base64 value
  if [ -n "$VKDR_ENV_DEVPORTAL_GITHUB_PRIVATE_KEY_BASE64" ]; then
    VKDR_DEVPORTAL_GITHUB_PRIVATE_KEY=$(echo "$VKDR_ENV_DEVPORTAL_GITHUB_PRIVATE_KEY_BASE64" | base64 --decode)
    # check if private key starts with "-----BEGIN.*PRIVATE KEY-----"
    if [[ ! "$VKDR_DEVPORTAL_GITHUB_PRIVATE_KEY" =~ ^-----BEGIN.*PRIVATE\ KEY----- ]]; then
      error "prepareGitHubEnv: GITHUB_PRIVATE_KEY_BASE64 is not a valid private key"
      return 1
    fi
  else
    debug "prepareGitHubEnv: GITHUB_PRIVATE_KEY_BASE64 not provided, skipping..."
  fi
}

prepareEnv() {
  # prepare env vars
  # load from environment variables if --load-env is true
  if [[ "$VKDR_ENV_DEVPORTAL_LOAD_ENV" == "true" ]]; then
    debug "prepareEnv: loading profile values from environment variables"

    # GitHub-related environment variables
    [ -z "$VKDR_ENV_DEVPORTAL_GITHUB_TOKEN" ] && [ -n "$GITHUB_TOKEN" ] && VKDR_ENV_DEVPORTAL_GITHUB_TOKEN="$GITHUB_TOKEN"
    [ -z "$VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_ID" ] && [ -n "$GITHUB_CLIENT_ID" ] && VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_ID="$GITHUB_CLIENT_ID"
    [ -z "$VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_SECRET" ] && [ -n "$GITHUB_CLIENT_SECRET" ] && VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_SECRET="$GITHUB_CLIENT_SECRET"
    [ -z "$VKDR_ENV_DEVPORTAL_GITHUB_AUTH_CLIENT_ID" ] && [ -n "$GITHUB_AUTH_CLIENT_ID" ] && VKDR_ENV_DEVPORTAL_GITHUB_AUTH_CLIENT_ID="$GITHUB_AUTH_CLIENT_ID"
    [ -z "$VKDR_ENV_DEVPORTAL_GITHUB_AUTH_CLIENT_SECRET" ] && [ -n "$GITHUB_AUTH_CLIENT_SECRET" ] && VKDR_ENV_DEVPORTAL_GITHUB_AUTH_CLIENT_SECRET="$GITHUB_AUTH_CLIENT_SECRET"
    [ -z "$VKDR_ENV_DEVPORTAL_GITHUB_APP_ID" ] && [ -n "$GITHUB_APP_ID" ] && VKDR_ENV_DEVPORTAL_GITHUB_APP_ID="$GITHUB_APP_ID"
    [ -z "$VKDR_ENV_DEVPORTAL_GITHUB_ORG" ] && [ -n "$GITHUB_ORG" ] && VKDR_ENV_DEVPORTAL_GITHUB_ORG="$GITHUB_ORG"
    [ -z "$VKDR_ENV_DEVPORTAL_GITHUB_PRIVATE_KEY_BASE64" ] && [ -n "$GITHUB_PRIVATE_KEY_BASE64" ] && VKDR_ENV_DEVPORTAL_GITHUB_PRIVATE_KEY_BASE64="$GITHUB_PRIVATE_KEY_BASE64"
  fi

  if [[ "$VKDR_ENV_DEVPORTAL_PROFILE" == "github" ]]; then
    prepareGitHubEnv
  fi
}

startInfos() {
  boldInfo "DevPortal Install"
  bold "=============================="
  boldNotice "Domain: $VKDR_ENV_DEVPORTAL_DOMAIN"
  boldNotice "Secure: $VKDR_ENV_DEVPORTAL_SECURE"
  boldNotice "Profile: $VKDR_ENV_DEVPORTAL_PROFILE"
  if [[ "$VKDR_ENV_DEVPORTAL_PROFILE" == "github" || "$VKDR_ENV_DEVPORTAL_PROFILE" == "github-pat" ]]; then
    boldNotice "Github Org: $VKDR_ENV_DEVPORTAL_GITHUB_ORG"
    boldNotice "Github Token: *****${VKDR_ENV_DEVPORTAL_GITHUB_TOKEN: -3}"
  fi
  if [[ "$VKDR_ENV_DEVPORTAL_PROFILE" == "github" ]]; then
    boldNotice "Github Client ID: *****${VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_ID: -3}"
    boldNotice "Github Client Secret: *****${VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_SECRET: -3}"
    boldNotice "Github Auth Client ID: *****${VKDR_ENV_DEVPORTAL_GITHUB_AUTH_CLIENT_ID: -3}"
    boldNotice "Github Auth Client Secret: *****${VKDR_ENV_DEVPORTAL_GITHUB_AUTH_CLIENT_SECRET: -3}"
    boldNotice "Github App ID: $VKDR_ENV_DEVPORTAL_GITHUB_APP_ID"
    boldNotice "Github Private Key (base64): *****${VKDR_ENV_DEVPORTAL_GITHUB_PRIVATE_KEY_BASE64: -3}"
  fi
  boldNotice "Install Sample apps: $VKDR_ENV_DEVPORTAL_INSTALL_SAMPLES"
  boldNotice "Catalog location: $VKDR_ENV_DEVPORTAL_CATALOG_LOCATION"
  boldNotice "NPM registry: $VKDR_ENV_DEVPORTAL_NPM_REGISTRY"
  boldNotice "Merge values file: $VKDR_ENV_DEVPORTAL_MERGE_VALUES"
  bold "=============================="
  boldNotice "Cluster LB HTTP port: $VKDR_HTTP_PORT"
  boldNotice "Cluster LB HTTPS port: $VKDR_HTTPS_PORT"
  bold "=============================="
}

installDevPortal() {
  debug "installDevPortal: add/update helm repo"
  REPO_URL="https://veecode-platform.github.io/next-charts"
  #$VKDR_HELM repo add veecode-platform https://veecode-platform.github.io/public-charts/
  #$VKDR_HELM repo update veecode-platform
  debug "installDevPortal: installing DevPortal (beta)"
  #VKDR_PROTOCOL=http
  #if [[ "$VKDR_ENV_DEVPORTAL_SECURE" == "true" ]]; then VKDR_PROTOCOL=https; fi
  VKDR_DEVPORTAL_PORT=""
  if [ "true" = "$VKDR_ENV_DEVPORTAL_SECURE" ]; then
    VKDR_PROTOCOL="https"
    if [ "$VKDR_HTTPS_PORT" != "443" ]; then
      VKDR_DEVPORTAL_PORT=":$VKDR_HTTPS_PORT"
    fi
  else
    VKDR_PROTOCOL="http"
    if [ "$VKDR_HTTP_PORT" != "80" ]; then
      VKDR_DEVPORTAL_PORT=":$VKDR_HTTP_PORT"
    fi
  fi
  local LOCATION_TARGET="https://github.com/veecode-platform/vkdr-catalog/blob/main/catalog-info.yaml"
  if [ "true" = "$VKDR_ENV_DEVPORTAL_INSTALL_SAMPLES" ]; then
    LOCATION_TARGET="https://github.com/veecode-platform/vkdr-catalog/blob/main/catalog-info-samples.yaml"
  fi
  debug "installDevPortal: DevPortal install using helm chart, host ${VKDR_ENV_DEVPORTAL_DOMAIN}, port ${VKDR_DEVPORTAL_PORT}, protocol ${VKDR_PROTOCOL}"
  $VKDR_HELM upgrade veecode-devportal veecode-devportal --install --wait --timeout 10m \
    --repo "$REPO_URL" --create-namespace -n "$DEVPORTAL_NAMESPACE" \
    -f "$VKDR_DEVPORTAL_VALUES" \
    --set "global.host=devportal.${VKDR_ENV_DEVPORTAL_DOMAIN}" \
    --set "global.port=${VKDR_DEVPORTAL_PORT}" \
    --set "global.protocol=${VKDR_PROTOCOL}"
}

checkForKong() {
  # check if kong is installed
  if $VKDR_HELM list -n vkdr | grep -q "^kong"; then
    debug "checkForKong: Kong already installed."
    return 0;
  fi
  debug "checkForKong: Kong not found, will install it as default ingress controller:"
  debug "checkForKong: running 'vkdr kong install --default-ic' -m standard"
  (
    vkdr kong install --default-ic -t "3.9.1" -m standard
  )
}

generateServiceAccountToken() {
  debug "generateServiceAccountToken: generating service account token for later use"
  # SA name hard coded for now
  SERVICE_ACCOUNT_NAME="veecode-devportal-sa"
  #createDevPortalServiceAccount
  # debug "Generating token for $SERVICE_ACCOUNT_NAME namespace $SERVICE_ACCOUNT_NAMESPACE"
  VKDR_SERVICE_ACCOUNT_TOKEN=$($VKDR_KUBECTL create token ${SERVICE_ACCOUNT_NAME} -n ${DEVPORTAL_NAMESPACE} --duration=87600h)
  debug "generateServiceAccountToken: service account token = ${VKDR_SERVICE_ACCOUNT_TOKEN:0:10} (first 10 chars)"
  debug "generateServiceAccountToken: creating 'devportal-cluster-secret' secret for token (will be used by kubernetes plugin)"
  kubectl create secret generic cluster-vkdr-local-secret -n ${DEVPORTAL_NAMESPACE} \
    --from-literal=cluster-vkdr-local-secret="$VKDR_SERVICE_ACCOUNT_TOKEN" \
    --dry-run=client --save-config -o yaml | kubectl apply -f -
  debug "generateServiceAccountToken: secret 'devportal-cluster-secret' can now be used by kubernetes plugin dynamic discovery"
}

installSampleApps() {
  if [ "true" != "$VKDR_ENV_DEVPORTAL_INSTALL_SAMPLES" ]; then
    debug "installSampleApps: skipping sample apps installation"
    return
  fi
  debug "installSampleApps: installing sample apps"
  local VKDR_SAMPLES_PATH="$SHARED_DIR/sample-apps"
  $VKDR_KUBECTL apply -f "$VKDR_SAMPLES_PATH/petclinic.yaml" -n vkdr
  $VKDR_KUBECTL apply -f "$VKDR_SAMPLES_PATH/viacep-api.yaml" -n vkdr
}

# secrets usadas pelo backstage, chart veecode-devportal as monta como env vars
createSecret() {
  debug "createSecret: creating secret for profile '$VKDR_ENV_DEVPORTAL_PROFILE'"

  case "$VKDR_ENV_DEVPORTAL_PROFILE" in
    github-pat)
      debug "createSecret: creating secret for github-pat profile"
      $VKDR_KUBECTL create secret generic backstage-secrets \
        --from-literal=VEECODE_PROFILE=github-pat \
        --from-literal=GITHUB_TOKEN=${VKDR_ENV_DEVPORTAL_GITHUB_TOKEN} \
        --from-literal=GITHUB_ORG=${VKDR_ENV_DEVPORTAL_GITHUB_ORG} \
        --dry-run=client --save-config -o yaml | $VKDR_KUBECTL apply -n "$DEVPORTAL_NAMESPACE" -f -
      ;;
    github)
      debug "createSecret: creating secret for github profile"
      # write private key to temp file for kubectl
      local TEMP_PK_FILE="/tmp/github-pk-$$.pem"
      echo "$VKDR_DEVPORTAL_GITHUB_PRIVATE_KEY" > "$TEMP_PK_FILE"
      # ensure cleanup even if command fails
      trap "rm -f '$TEMP_PK_FILE'" EXIT

      $VKDR_KUBECTL create secret generic backstage-secrets \
        --from-literal=VEECODE_PROFILE=github \
        --from-literal=GITHUB_TOKEN=${VKDR_ENV_DEVPORTAL_GITHUB_TOKEN} \
        --from-literal=GITHUB_CLIENT_ID=${VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_ID} \
        --from-literal=GITHUB_CLIENT_SECRET=${VKDR_ENV_DEVPORTAL_GITHUB_CLIENT_SECRET} \
        --from-literal=GITHUB_AUTH_CLIENT_ID=${VKDR_ENV_DEVPORTAL_GITHUB_AUTH_CLIENT_ID} \
        --from-literal=GITHUB_AUTH_CLIENT_SECRET=${VKDR_ENV_DEVPORTAL_GITHUB_AUTH_CLIENT_SECRET} \
        --from-literal=GITHUB_APP_ID=${VKDR_ENV_DEVPORTAL_GITHUB_APP_ID} \
        --from-literal=GITHUB_ORG=${VKDR_ENV_DEVPORTAL_GITHUB_ORG} \
        --from-file=GITHUB_PRIVATE_KEY="$TEMP_PK_FILE" \
        --dry-run=client --save-config -o yaml | $VKDR_KUBECTL apply -n "$DEVPORTAL_NAMESPACE" -f -

      # cleanup temp file
      rm -f "$TEMP_PK_FILE"
      trap - EXIT
      ;;
    gitlab)
      error "Profile 'gitlab' is not implemented yet"
      return 1
      ;;
    azure)
      error "Profile 'azure' is not implemented yet"
      return 1
      ;;
    ldap)
      error "Profile 'ldap' is not implemented yet"
      return 1
      ;;
    *)
      debug "createSecret: creating secret for default/no profile"
      $VKDR_KUBECTL create secret generic backstage-secrets \
        --from-literal=VEECODE_PROFILE=local \
        --dry-run=client --save-config -o yaml | $VKDR_KUBECTL apply -n "$DEVPORTAL_NAMESPACE" -f -
      ;;
  esac
}

createDevPortalNamespace() {
  debug "createDevPortalNamespace: creating namespace '$DEVPORTAL_NAMESPACE'"
  echo "
apiVersion: v1
kind: Namespace
metadata:
  name: $DEVPORTAL_NAMESPACE
" | $VKDR_KUBECTL apply -f -
}

settingDevPortal() {
  # copies values file for modification
  cp "$VKDR_DEVPORTAL_VALUES_SRC" "$VKDR_DEVPORTAL_VALUES"
}

mergeValues() {
  if [ -z "$VKDR_ENV_DEVPORTAL_MERGE_VALUES" ]; then
    debug "mergeValues: no merge values file specified, skipping..."
    return
  fi
  debug "mergeValues: merging values file $VKDR_ENV_DEVPORTAL_MERGE_VALUES into $VKDR_DEVPORTAL_VALUES"
  $VKDR_YQ eval-all -i 'select(fileIndex == 0) *+ select(fileIndex == 1)' "$VKDR_DEVPORTAL_VALUES" "$VKDR_ENV_DEVPORTAL_MERGE_VALUES"
}

setLocations() {
  local LOCATION_TARGET="https://github.com/veecode-platform/vkdr-catalog/blob/main/catalog-info.yaml"
  if [ "true" = "$VKDR_ENV_DEVPORTAL_INSTALL_SAMPLES" ]; then
    LOCATION_TARGET="https://github.com/veecode-platform/vkdr-catalog/blob/main/catalog-info-samples.yaml"
  fi
  # add location to values file under "upstream.backstage.appConfig.catalog.locations"
  $VKDR_YQ eval ".upstream.backstage.appConfig.catalog.locations += [{\"type\": \"url\", \"target\": \"$LOCATION_TARGET\"}]" -i "$VKDR_DEVPORTAL_VALUES"
  # if VKDR_ENV_DEVPORTAL_CATALOG_LOCATION is set, add it to values file under "upstream.backstage.appConfig.catalog.locations"
  if [ -n "$VKDR_ENV_DEVPORTAL_CATALOG_LOCATION" ]; then
    $VKDR_YQ eval ".upstream.backstage.appConfig.catalog.locations += [{\"type\": \"url\", \"target\": \"$VKDR_ENV_DEVPORTAL_CATALOG_LOCATION\"}]" -i "$VKDR_DEVPORTAL_VALUES"
  fi
  debug "setLocations: patched locations into $VKDR_DEVPORTAL_VALUES"
}

# important: this secret should be mounted as a volume in the backstage pod automatically
# see https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.4/html/installing_and_viewing_plugins_in_red_hat_developer_hub/assembly-third-party-plugins#proc-load-plugin-js-package_assembly-install-third-party-plugins-rhdh
# the magic matches the secret name with the release name and a suffix "-dynamic-plugins-npmrc"
setRegistry() {
  if [ -z "$VKDR_ENV_DEVPORTAL_NPM_REGISTRY" ]; then
    debug "setRegistry: npm registry not set, skipping..."
    return
  fi
  debug "setRegistry: criando secret para npm registry $VKDR_ENV_DEVPORTAL_NPM_REGISTRY"
  $VKDR_KUBECTL create secret generic veecode-devportal-dynamic-plugins-npmrc -n ${DEVPORTAL_NAMESPACE} \
    "--from-literal=.npmrc=registry=$VKDR_ENV_DEVPORTAL_NPM_REGISTRY" \
    --type=Opaque --dry-run=client -o yaml | $VKDR_KUBECTL apply -f -
}

runFormula() {
  detectClusterPorts
  prepareEnv
  startInfos
  checkDockerEngine
  settingDevPortal
  checkForKong
  createDevPortalNamespace
  createSecret
  setLocations
  setRegistry
  mergeValues
  installDevPortal
  generateServiceAccountToken
  installSampleApps
}

runFormula
