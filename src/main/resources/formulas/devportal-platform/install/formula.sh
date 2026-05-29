#!/usr/bin/env bash

# vkdr devportal-platform install — installs DevPortal V2 (presets-based) from the
# published veecode-devportal-platform Helm chart. Distinct from `vkdr devportal install`
# (V1). Args are positional, passed by VkdrDevPortalPlatformInstallCommand.

VKDR_ENV_DOMAIN=$1
VKDR_ENV_SECURE=$2
VKDR_ENV_PRESETS=$3
VKDR_ENV_GITHUB_PAT=$4
VKDR_ENV_GITHUB_ORG=$5
VKDR_ENV_GITHUB_AUTH_CLIENT_ID=$6
VKDR_ENV_GITHUB_AUTH_CLIENT_SECRET=$7
VKDR_ENV_WITH_KUBERNETES=$8
VKDR_ENV_PLUGIN_REGISTRY=$9
VKDR_ENV_INSTALL_SAMPLES=${10}
VKDR_ENV_LOCATION=${11}
VKDR_ENV_MERGE_VALUES=${12}
VKDR_ENV_LOAD_ENV=${13}

FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"
source "$SHARED_DIR/lib/ingress-tools.sh"
source "$SHARED_DIR/lib/docker-tools.sh"

VKDR_VALUES_SRC="$SHARED_DIR/values/devportal-platform-common.yaml"
VKDR_VALUES="/tmp/devportal-platform.yaml"
DEVPORTAL_NAMESPACE=platform
RELEASE_NAME=veecode-devportal-platform
CHART_NAME=veecode-devportal-platform
CHART_REPO="https://veecode-platform.github.io/next-charts"
SECRET_NAME=devportal-platform-secrets
K8S_SA_NAME=veecode-devportal-platform-k8s-reader

# overridden by detectClusterPorts
VKDR_HTTP_PORT=8000
VKDR_HTTPS_PORT=8001
VKDR_FINAL_PRESETS=""
VKDR_K8S_TOKEN=""

prepareEnv() {
  if [[ "$VKDR_ENV_LOAD_ENV" == "true" ]]; then
    debug "prepareEnv: loading GitHub credentials from environment"
    [ -z "$VKDR_ENV_GITHUB_PAT" ] && [ -n "$GITHUB_PAT" ] && VKDR_ENV_GITHUB_PAT="$GITHUB_PAT"
    [ -z "$VKDR_ENV_GITHUB_ORG" ] && [ -n "$GITHUB_ORG" ] && VKDR_ENV_GITHUB_ORG="$GITHUB_ORG"
    [ -z "$VKDR_ENV_GITHUB_AUTH_CLIENT_ID" ] && [ -n "$GITHUB_AUTH_CLIENT_ID" ] && VKDR_ENV_GITHUB_AUTH_CLIENT_ID="$GITHUB_AUTH_CLIENT_ID"
    [ -z "$VKDR_ENV_GITHUB_AUTH_CLIENT_SECRET" ] && [ -n "$GITHUB_AUTH_CLIENT_SECRET" ] && VKDR_ENV_GITHUB_AUTH_CLIENT_SECRET="$GITHUB_AUTH_CLIENT_SECRET"
  fi
}

# Final preset list = --presets + auto-added presets whose credentials/flags are present.
# Dedup, preserve order. (github needs PAT+ORG; github-auth needs the OAuth pair.)
composePresets() {
  local list="$VKDR_ENV_PRESETS"
  if [ -n "$VKDR_ENV_GITHUB_PAT" ] && [ -n "$VKDR_ENV_GITHUB_ORG" ]; then list="$list,github"; fi
  if [ -n "$VKDR_ENV_GITHUB_AUTH_CLIENT_ID" ] && [ -n "$VKDR_ENV_GITHUB_AUTH_CLIENT_SECRET" ]; then list="$list,github-auth"; fi
  if [ "$VKDR_ENV_WITH_KUBERNETES" == "true" ]; then list="$list,kubernetes"; fi
  VKDR_FINAL_PRESETS=$(echo "$list" | tr ',' '\n' | awk 'NF && !seen[$0]++' | paste -sd, -)
}

startInfos() {
  boldInfo "DevPortal V2 (devportal-platform) Install"
  bold "=============================="
  boldNotice "Domain: $VKDR_ENV_DOMAIN"
  boldNotice "Presets: $VKDR_FINAL_PRESETS"
  boldNotice "With kubernetes preset: $VKDR_ENV_WITH_KUBERNETES"
  [ -n "$VKDR_ENV_GITHUB_ORG" ] && boldNotice "GitHub org: $VKDR_ENV_GITHUB_ORG"
  [ -n "$VKDR_ENV_PLUGIN_REGISTRY" ] && boldNotice "Plugin registry: $VKDR_ENV_PLUGIN_REGISTRY"
  boldNotice "Install samples: $VKDR_ENV_INSTALL_SAMPLES"
  bold "=============================="
}

checkForKong() {
  if $VKDR_HELM list -n vkdr | grep -q "^kong"; then
    debug "checkForKong: Kong already installed."
    return 0
  fi
  debug "checkForKong: installing Kong as default ingress controller"
  ( vkdr kong install --default-ic -t "3.9.1" -m standard )
}

createDevPortalNamespace() {
  echo "
apiVersion: v1
kind: Namespace
metadata:
  name: $DEVPORTAL_NAMESPACE
" | $VKDR_KUBECTL apply -f -
}

# When --with-kubernetes: VKDR owns the RBAC (chart's rbac.clusterRoles.create stays
# false). Create a read-only SA + ClusterRole + binding and mint a long-lived token
# the kubernetes preset consumes via K8S_CLUSTER_TOKEN.
setupKubernetesSA() {
  debug "setupKubernetesSA: creating read-only SA + ClusterRole for the kubernetes preset"
  echo "
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $K8S_SA_NAME
  namespace: $DEVPORTAL_NAMESPACE
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: $K8S_SA_NAME
rules:
  - apiGroups: [\"\"]
    resources: [configmaps, limitranges, namespaces, nodes, pods, resourcequotas, services]
    verbs: [get, list, watch]
  - apiGroups: [\"apps\"]
    resources: [daemonsets, deployments, replicasets, statefulsets]
    verbs: [get, list, watch]
  - apiGroups: [\"autoscaling\"]
    resources: [horizontalpodautoscalers]
    verbs: [get, list, watch]
  - apiGroups: [\"networking.k8s.io\"]
    resources: [ingresses, ingressclasses]
    verbs: [get, list, watch]
  - apiGroups: [\"batch\"]
    resources: [jobs, cronjobs]
    verbs: [get, list, watch]
  - apiGroups: [\"metrics.k8s.io\"]
    resources: [pods]
    verbs: [get, list]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $K8S_SA_NAME
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: $K8S_SA_NAME
subjects:
  - kind: ServiceAccount
    name: $K8S_SA_NAME
    namespace: $DEVPORTAL_NAMESPACE
" | $VKDR_KUBECTL apply -f -
  VKDR_K8S_TOKEN=$($VKDR_KUBECTL create token "$K8S_SA_NAME" -n "$DEVPORTAL_NAMESPACE" --duration=87600h)
}

# VKDR-managed credentials Secret consumed by the chart via existingSecret (envFrom).
# Keeps secrets out of the Helm release. Only sets the vars actually provided.
createSecret() {
  debug "createSecret: building $SECRET_NAME from provided credentials"
  local args=()
  [ -n "$VKDR_ENV_GITHUB_PAT" ] && args+=("--from-literal=GITHUB_PAT=$VKDR_ENV_GITHUB_PAT")
  [ -n "$VKDR_ENV_GITHUB_ORG" ] && args+=("--from-literal=GITHUB_ORG=$VKDR_ENV_GITHUB_ORG")
  [ -n "$VKDR_ENV_GITHUB_AUTH_CLIENT_ID" ] && args+=("--from-literal=GITHUB_AUTH_CLIENT_ID=$VKDR_ENV_GITHUB_AUTH_CLIENT_ID")
  [ -n "$VKDR_ENV_GITHUB_AUTH_CLIENT_SECRET" ] && args+=("--from-literal=GITHUB_AUTH_CLIENT_SECRET=$VKDR_ENV_GITHUB_AUTH_CLIENT_SECRET")
  if [ "$VKDR_ENV_WITH_KUBERNETES" == "true" ]; then
    setupKubernetesSA
    args+=("--from-literal=K8S_CLUSTER_NAME=vkdr-local")
    args+=("--from-literal=K8S_CLUSTER_URL=https://kubernetes.default.svc")
    args+=("--from-literal=K8S_CLUSTER_TOKEN=$VKDR_K8S_TOKEN")
  fi
  $VKDR_KUBECTL create secret generic "$SECRET_NAME" -n "$DEVPORTAL_NAMESPACE" "${args[@]}" \
    --dry-run=client -o yaml | $VKDR_KUBECTL apply -f -
}

settingValues() {
  cp "$VKDR_VALUES_SRC" "$VKDR_VALUES"
}

patchValues() {
  $VKDR_YQ eval ".presets = (\"$VKDR_FINAL_PRESETS\" | split(\",\"))" -i "$VKDR_VALUES"
  $VKDR_YQ eval ".existingSecret = \"$SECRET_NAME\"" -i "$VKDR_VALUES"
  $VKDR_YQ eval ".ingress.hosts[0].host = \"devportal.$VKDR_ENV_DOMAIN\"" -i "$VKDR_VALUES"
  if [ -n "$VKDR_ENV_PLUGIN_REGISTRY" ]; then
    $VKDR_YQ eval ".pluginRegistry = \"$VKDR_ENV_PLUGIN_REGISTRY\"" -i "$VKDR_VALUES"
  fi
  # Catalog locations (always at least the vkdr demo catalog, like V1)
  local loc="https://github.com/veecode-platform/vkdr-catalog/blob/main/catalog-info.yaml"
  if [ "$VKDR_ENV_INSTALL_SAMPLES" == "true" ]; then
    loc="https://github.com/veecode-platform/vkdr-catalog/blob/main/catalog-info-samples.yaml"
  fi
  $VKDR_YQ eval ".appConfig.catalog.locations += [{\"type\":\"url\",\"target\":\"$loc\"}]" -i "$VKDR_VALUES"
  if [ -n "$VKDR_ENV_LOCATION" ]; then
    $VKDR_YQ eval ".appConfig.catalog.locations += [{\"type\":\"url\",\"target\":\"$VKDR_ENV_LOCATION\"}]" -i "$VKDR_VALUES"
  fi
}

mergeValues() {
  if [ -z "$VKDR_ENV_MERGE_VALUES" ]; then return; fi
  debug "mergeValues: merging $VKDR_ENV_MERGE_VALUES"
  $VKDR_YQ eval-all -i 'select(fileIndex == 0) *+ select(fileIndex == 1)' "$VKDR_VALUES" "$VKDR_ENV_MERGE_VALUES"
}

installDevPortal() {
  debug "installDevPortal: helm upgrade --install $RELEASE_NAME from $CHART_REPO"
  $VKDR_HELM upgrade "$RELEASE_NAME" "$CHART_NAME" --install --wait --timeout 10m \
    --repo "$CHART_REPO" --create-namespace -n "$DEVPORTAL_NAMESPACE" \
    -f "$VKDR_VALUES"
}

installSampleApps() {
  if [ "$VKDR_ENV_INSTALL_SAMPLES" != "true" ]; then return; fi
  debug "installSampleApps: applying sample apps"
  $VKDR_KUBECTL apply -f "$SHARED_DIR/sample-apps/petclinic.yaml" -n vkdr
  $VKDR_KUBECTL apply -f "$SHARED_DIR/sample-apps/viacep-api.yaml" -n vkdr
}

runFormula() {
  detectClusterPorts
  prepareEnv
  composePresets
  startInfos
  checkDockerEngine
  checkForKong
  createDevPortalNamespace
  createSecret
  settingValues
  patchValues
  mergeValues
  installDevPortal
  installSampleApps
}

runFormula
