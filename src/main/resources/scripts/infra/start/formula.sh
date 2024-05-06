#!/usr/bin/env bash

# parametros posicionais na formula
VKDR_ENV_TRAEFIK=$1
VKDR_ENV_HTTP_PORT=$2
VKDR_ENV_HTTPS_PORT=$3
VKDR_ENV_NUMBER_NODEPORTS=$4
VKDR_ENV_API_PORT=$5
VKDR_ENV_VOLUMES=$6
# internal
NODEPORT_FLAG=""
NODEPORT_VALUE=""
TRAEFIK_FLAG=""
TRAEFIK_VALUE=""
VOLUMES_ARRAY=()

source "$(dirname "$0")/../../.util/log.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"

startInfos() {
  bold "=============================="
  boldInfo "VKDR Local Infra Start Routine"
  boldNotice "Enabled Traefik Ingress Controller: ${VKDR_ENV_TRAEFIK}"
  boldNotice "Ports Used: ${VKDR_ENV_HTTP_PORT}/http :${VKDR_ENV_HTTPS_PORT}/https"
  if [ -z "$VKDR_ENV_API_PORT" ]; then
    boldNotice "Kubernetes API port: random"
  else
    boldNotice "Kubernetes API port: ${VKDR_ENV_API_PORT}"
  fi
  #boldNotice "Local Registry: 6000"
  boldNotice "Local Docker Hub Registry Mirror (cache): 6001"
  if [ $VKDR_ENV_NUMBER_NODEPORTS -gt 0 ] ; then
    boldNotice "NodePorts available: 9000-$((VKDR_ENV_NUMBER_NODEPORTS+9000-1)):30000-$((VKDR_ENV_NUMBER_NODEPORTS+30000-1))"
  else
    boldNotice "NodePorts disabled"
  fi
  #boldWarn "Using two local unamed Docker Volumes"
  bold "=============================="
}

# Create the local registry and Docker Hub Mirror
startRegistry() {
  #if ! ${VKDR_K3D} registry list | grep -q "k3d-registry\.localhost"; then
  #  ${VKDR_K3D} registry create registry.localhost \
  #    -p 6000 -v vkdr-registry:/var/lib/registry
  #else
  #  warn "Registry already started, skipping..."
  #fi

  if ! ${VKDR_K3D} registry list | grep -q "k3d-docker-io"; then
    ${VKDR_K3D} registry create docker-io \
      --proxy-remote-url https://registry-1.docker.io \
      -p 6001 -v vkdr-mirror-registry:/var/lib/registry
  else
    warn "Mirror already started, skipping..."
  fi
}

# Starts K8S using Registries
startCluster() {
  if $VKDR_K3D cluster list | grep -q "vkdr-local"; then
    error "Cluster vkdr-local already created."
    return
  fi
  info "Mirror from $(dirname "$0")/../../.util/configs/mirror-registry.yaml"
  cat "$(dirname "$0")/../../.util/configs/mirror-registry.yaml"
  [[ -z "$VKDR_ENV_API_PORT" ]] && API_PORT_FLAG="" || API_PORT_FLAG="--api-port"
  $VKDR_K3D cluster create vkdr-local $API_PORT_FLAG $VKDR_ENV_API_PORT \
    -p "$VKDR_ENV_HTTP_PORT:80@loadbalancer" \
    -p "$VKDR_ENV_HTTPS_PORT:443@loadbalancer" \
    --registry-use k3d-docker-io:6001  \
    --registry-config "$(dirname "$0")/../../.util/configs/mirror-registry.yaml" \
    $NODEPORT_FLAG $NODEPORT_VALUE $TRAEFIK_FLAG $TRAEFIK_VALUE "${VOLUMES_ARRAY[@]}"
  $VKDR_KUBECTL cluster-info
}

configureCluster() {
  if [ $VKDR_ENV_NUMBER_NODEPORTS -gt 0 ] ; then
    local PORT_LOCAL="$(($VKDR_ENV_NUMBER_NODEPORTS+9000-1))" \
          PORT_NODE="$(($VKDR_ENV_NUMBER_NODEPORTS+30000-1))"
    NODEPORT_FLAG="-p"
    NODEPORT_VALUE="9000-$PORT_LOCAL:30000-$PORT_NODE"
  fi
  if [ "$VKDR_ENV_TRAEFIK" == false ]; then
    TRAEFIK_FLAG="--k3s-arg"
    TRAEFIK_VALUE="--disable=traefik@server:0"
  fi
}

parseVolumes() {
  local oldIFS="$IFS"
  local IFS=","
  for i in $VKDR_ENV_VOLUMES
  do
    echo "[$i] extracted"
    VOLUMES_ARRAY+=("--volume")
    VOLUMES_ARRAY+=("$i@server:0")
  done
  IFS="$oldIFS"
  echo "${VOLUMES_ARRAY[@]}"
}

startInfos
startRegistry
parseVolumes
configureCluster
startCluster
