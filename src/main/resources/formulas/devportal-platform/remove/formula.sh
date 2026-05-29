#!/usr/bin/env bash

# vkdr devportal-platform remove — uninstalls the DevPortal V2 release.

FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

DEVPORTAL_NAMESPACE=platform
RELEASE_NAME=veecode-devportal-platform
SECRET_NAME=devportal-platform-secrets
K8S_SA_NAME=veecode-devportal-platform-k8s-reader

startInfos() {
  boldInfo "DevPortal V2 (devportal-platform) Remove"
  bold "=============================="
}

remove() {
  $VKDR_HELM delete "$RELEASE_NAME" -n "$DEVPORTAL_NAMESPACE" 2>/dev/null || debug "remove: release not found"
  $VKDR_KUBECTL delete secret "$SECRET_NAME" -n "$DEVPORTAL_NAMESPACE" --ignore-not-found=true
  # VKDR-owned kubernetes-preset RBAC (cluster-scoped), if it was created
  $VKDR_KUBECTL delete clusterrolebinding "$K8S_SA_NAME" --ignore-not-found=true
  $VKDR_KUBECTL delete clusterrole "$K8S_SA_NAME" --ignore-not-found=true
  $VKDR_KUBECTL delete serviceaccount "$K8S_SA_NAME" -n "$DEVPORTAL_NAMESPACE" --ignore-not-found=true
}

runFormula() {
  startInfos
  remove
}

runFormula
