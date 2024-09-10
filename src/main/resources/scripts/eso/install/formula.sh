#!/usr/bin/env bash

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

ESO_NAMESPACE=vkdr

startInfos() {
  boldInfo "ESO Install"
  bold "=============================="
  bold "=============================="
}

installESO() {
  debug "installESO: add/update helm repo"
  $VKDR_HELM repo add external-secrets https://charts.external-secrets.io
  $VKDR_HELM repo update external-secrets
  debug "installESO: installing External Secrets Operator"
  $VKDR_HELM upgrade --install external-secrets external-secrets/external-secrets \
    -n $ESO_NAMESPACE
}

runFormula() {
  startInfos
  createESONamespace
  installESO
}

createESONamespace() {
  debug "Create ESO namespace '$ESO_NAMESPACE'"
  echo "
apiVersion: v1
kind: Namespace
metadata:
  name: $ESO_NAMESPACE
" | $VKDR_KUBECTL apply -f -
}

runFormula
