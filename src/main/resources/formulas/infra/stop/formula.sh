#!/usr/bin/env bash

# parametros posicionais na formula
VKDR_ENV_DELETE_REGISTRY=$1

# V2 paths: relative to formulas/infra/stop/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"

source "$SHARED_DIR/lib/log.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/docker-tools.sh"

MIRROR_CONFIG="${HOME}/.vkdr/configs/mirror-registry.yaml"

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
    debug "stopCluster: parsing mirror config from $MIRROR_CONFIG"
    MIRRORS=$($VKDR_YQ -r '.mirrors | keys[]' "$MIRROR_CONFIG")
    debug "startMirrors: reading current registry list"
    # avoid DEBUG output from k3d
    K3D_JSON=$(LOG_LEVEL=error $VKDR_K3D registry list -o json)
    REGISTRIES=$(echo "$K3D_JSON" | $VKDR_JQ -r '.[].name')
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
