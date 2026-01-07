#!/bin/bash

createDevPortalServiceAccount() {
  local MYPATH="$(dirname "$0")/../../.util/devportal-k8s-service-account"
  $VKDR_KUBECTL apply -f "$MYPATH/cluster-role.yaml"
  $VKDR_KUBECTL apply -f "$MYPATH/service-account.yaml"
  $VKDR_KUBECTL apply -f "$MYPATH/cluster-role-binding.yaml"

  SERVICE_ACCOUNT_NAME=$(cat "$MYPATH/service-account.yaml" | $VKDR_YQ -e '.metadata.name')
  SERVICE_ACCOUNT_NAMESPACE=$(cat "$MYPATH/service-account.yaml" | $VKDR_YQ -e '.metadata.namespace // "default"')
  # debug "Generating token for $SERVICE_ACCOUNT_NAME namespace $SERVICE_ACCOUNT_NAMESPACE"
  export VKDR_SERVICE_ACCOUNT_TOKEN=$($VKDR_KUBECTL create token ${SERVICE_ACCOUNT_NAME} -n ${SERVICE_ACCOUNT_NAMESPACE} --duration=87600h)
}
