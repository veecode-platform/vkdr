#!/usr/bin/env bash

# parametros posicionais na formula
VKDR_ENV_TRAEFIK=$1
VKDR_ENV_HTTP_PORT=$2
VKDR_ENV_HTTPS_PORT=$3
VKDR_ENV_NUMBER_NODEPORTS=$4
VKDR_ENV_API_PORT=$5
VKDR_ENV_AGENTS=$6
VKDR_ENV_VOLUMES=$7
VKDR_ENV_NODEPORT_BASE=$8
# internal
NODEPORT_FLAG=""
NODEPORT_VALUE=""
TRAEFIK_FLAG=""
TRAEFIK_VALUE=""
VOLUMES_ARRAY=()
AGENTS_FLAG=""
AGENTS_VALUE=""

source "$(dirname "$0")/../../.util/log.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/docker-tools.sh"

MIRROR_CONFIG="${HOME}/.vkdr/scripts/.util/configs/mirror-registry.yaml"

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
    boldNotice "NodePorts available: ${VKDR_ENV_NODEPORT_BASE}-$((VKDR_ENV_NUMBER_NODEPORTS+VKDR_ENV_NODEPORT_BASE-1)):30000-$((VKDR_ENV_NUMBER_NODEPORTS+30000-1))"
  else
    boldNotice "NodePorts disabled"
  fi
  boldNotice "K3d Node Agents: ${VKDR_ENV_AGENTS}"
  #boldWarn "Using two local unamed Docker Volumes"
  bold "=============================="
}

startLocalRegistry() {
  debug "startLocalRegistry: TODO"
  #if ! ${VKDR_K3D} registry list | grep -q "k3d-registry\.localhost"; then
  #  ${VKDR_K3D} registry create registry.localhost \
  #    -p 6000 -v vkdr-registry:/var/lib/registry
  #else
  #  warn "Registry already started, skipping..."
  #fi
}

# Create the local registry and Docker Hub Mirror
startRegistry() {
  local mirror_name=$1
  local mirror_host=$2
  local mirror_port=$3
  if [ "docker-io" = "$mirror_name" ]; then
    ${VKDR_K3D} registry create docker-io \
      --proxy-remote-url https://registry-1.docker.io \
      -p $mirror_port -v vkdr-mirror-registry:/var/lib/registry
  else
    ${VKDR_K3D} registry create $mirror_name \
      --proxy-remote-url https://$mirror_host \
      -p $mirror_port -v vkdr-${mirror_name}-mirror-registry:/var/lib/registry
  fi
}

startMirrors() {
  local MIRRORS
  local MIRROR_NAME
  local REGISTRIES
  debug "startMirrors: parsing mirror config from $MIRROR_CONFIG"
  MIRRORS=$($VKDR_YQ -r '.mirrors | keys[]' "$MIRROR_CONFIG")
  debug "startMirrors: reading current registry list"
  REGISTRIES=$($VKDR_K3D registry list -o json | $VKDR_JQ -r '.[].name')
  debug "startMirrors: current registries: $REGISTRIES"
  for mirror in $MIRRORS; do
    MIRROR_NAME="${mirror//./-}"
    if echo "$REGISTRIES" | grep -qx "k3d-$MIRROR_NAME"; then
      debug "startMirrors: Mirror $MIRROR_NAME already started, skipping..."
    else
      # pegar porta do endpoint
      export MY_MIRROR="$mirror"
      MY_PORT=$($VKDR_YQ e '.mirrors[strenv(MY_MIRROR)].endpoint[0] | select(.) | split(":") | .[-1]' "$MIRROR_CONFIG")
      debug "startMirrors: will start mirror $mirror as $MIRROR_NAME registry in port $MY_PORT..."
      startRegistry $MIRROR_NAME $mirror $MY_PORT
    fi
  done
}

# Create the k3d cluster
# Starts K8S using Registries
startCluster() {
  if $VKDR_K3D cluster list | grep -q "vkdr-local"; then
    error "Cluster vkdr-local already created."
    return
  fi
  info "Mirror from $MIRROR_CONFIG"
  cat "$MIRROR_CONFIG"
  [[ -z "$VKDR_ENV_API_PORT" ]] && API_PORT_FLAG="" || API_PORT_FLAG="--api-port"
  $VKDR_K3D cluster create vkdr-local $API_PORT_FLAG $VKDR_ENV_API_PORT \
    -p "$VKDR_ENV_HTTP_PORT:80@loadbalancer" \
    -p "$VKDR_ENV_HTTPS_PORT:443@loadbalancer" \
    --registry-use k3d-docker-io:6001  \
    --registry-config "$MIRROR_CONFIG" \
    $NODEPORT_FLAG $NODEPORT_VALUE $TRAEFIK_FLAG $TRAEFIK_VALUE $AGENTS_FLAG $AGENTS_VALUE "${VOLUMES_ARRAY[@]}"
  $VKDR_KUBECTL cluster-info
}

configureCluster() {
  if [ $VKDR_ENV_NUMBER_NODEPORTS -gt 0 ] ; then
    local PORT_LOCAL="$(($VKDR_ENV_NUMBER_NODEPORTS+VKDR_ENV_NODEPORT_BASE-1))" \
          PORT_NODE="$(($VKDR_ENV_NUMBER_NODEPORTS+30000-1))"
    NODEPORT_FLAG="-p"
    NODEPORT_VALUE="${VKDR_ENV_NODEPORT_BASE}-$PORT_LOCAL:30000-$PORT_NODE"
  fi
  if [ "$VKDR_ENV_TRAEFIK" == false ]; then
    TRAEFIK_FLAG="--k3s-arg"
    TRAEFIK_VALUE="--disable=traefik@server:0"
  fi
  if [ "0" != "$VKDR_ENV_AGENTS" ]; then
    AGENTS_FLAG="--agents"
    AGENTS_VALUE="$VKDR_ENV_AGENTS"
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
  debug "parseVolumes: ${VOLUMES_ARRAY[@]}"
}

postStart() {
  boldInfo "K3D cluster 'vkdr-local' started"
  debug "postStart: patching 'localdomain' wildcard in coredns (needed for oidc)"
  $VKDR_KUBECTL apply -f "$(dirname "$0")/../../.util/configs/rewrite-coredns.yaml"
  $VKDR_KUBECTL -n kube-system rollout restart deployment coredns
  debug "postStart: patching 'localdomain' in coredns done, you can 'nslookup xxx.localdomain' from any pod to test it."
}

startInfos
checkDockerEngine
startMirrors
parseVolumes
configureCluster
startCluster
postStart
