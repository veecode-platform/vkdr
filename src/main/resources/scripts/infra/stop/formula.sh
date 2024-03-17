#!/usr/bin/env bash

# parametros posicionais na formula

VKDR_ENV_DELETE_REGISTRY=$1

source "$(dirname "$0")/../../.util/log.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"

runFormula() {
  startInfos
  stopCluster
}

startInfos() {
  bold "=============================="
  boldInfo "VKDR Local Infra Stop Routine"
  bold "=============================="
}

stopCluster() {
  if ${VKDR_K3D} cluster list | grep -q "vkdr-local"; then
    ${VKDR_K3D} cluster delete vkdr-local
  else
    error "Cluster vkdr-local not running..."
  fi
  if [[ $VKDR_ENV_DELETE_REGISTRY == "true" ]]; then
    #docker rm -f k3d-mirror.localhost k3d-registry.localhost > /dev/null
    if ${VKDR_K3D} cluster list | grep -q "k3d-registry"; then
      ${VKDR_K3D} registry delete k3d-registry.localhost
    else
      error "Registry k3d-registry not running..."
    fi
    if ${VKDR_K3D} cluster list | grep -q "k3d-mirror"; then
      ${VKDR_K3D} registry delete k3d-mirror.localhost
    else
      error "Registry k3d-mirror not running..."
    fi
  fi
}

runFormula
