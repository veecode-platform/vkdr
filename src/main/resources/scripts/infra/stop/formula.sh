#!/usr/bin/env bash

# parametros posicionais na formula

VKDR_ENV_DELETE_REGISTRY=$1

source "$(dirname "$0")/../../.util/log.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/docker-tools.sh"

#MIRROR_CONFIG="$(dirname "$0")/../../.util/configs/mirror-registry.yaml"
MIRROR_CONFIG="${HOME}/.vkdr/scripts/.util/configs/mirror-registry.yaml"

runFormula() {
  startInfos
  checkDockerEngine
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
    #if ${VKDR_K3D} registry list | grep -q "k3d-registry"; then
    #  ${VKDR_K3D} registry delete k3d-registry.localhost
    #else
    #  error "Registry k3d-registry not running..."
    #fi

    debug "stopCluster: parsing mirror config from $MIRROR_CONFIG"
    MIRRORS=$($VKDR_YQ -r '.mirrors | keys[]' "$MIRROR_CONFIG")
    debug "startMirrors: reading current registry list"
    REGISTRIES=$($VKDR_K3D registry list -o json | $VKDR_JQ -r '.[].name')
    for mirror in $MIRRORS; do
      MIRROR_NAME="${mirror//./-}"
      if echo "$REGISTRIES" | grep -qx "k3d-$MIRROR_NAME"; then
        debug "stopCluster: Deleting registry k3d-$MIRROR_NAME"
        ${VKDR_K3D} registry delete "k3d-$MIRROR_NAME"
      else
        error "Registry k3d-mirror not running..."
      fi
    done
  fi
}

runFormula
