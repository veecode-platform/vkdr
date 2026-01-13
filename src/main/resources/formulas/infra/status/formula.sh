#!/usr/bin/env bash

VKDR_ENV_JSON=$1

FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"

source "$SHARED_DIR/lib/log.sh"
source "$SHARED_DIR/lib/tools-paths.sh"

CLUSTER_NAME="vkdr-local"

checkClusterStatus() {
  local cluster_json
  local cluster_exists
  local servers_count
  local servers_running
  local api_server_ok

  # Get k3d cluster info
  cluster_json=$($VKDR_K3D cluster list -o json 2>/dev/null)
  if [ $? -ne 0 ]; then
    if [ "$VKDR_ENV_JSON" == "true" ]; then
      echo '{"cluster":"'"$CLUSTER_NAME"'","exists":false,"k3d_available":false,"status":"NOT_READY"}'
      return 0  # JSON mode always succeeds - status is in the output
    else
      boldError "k3d is not available or not responding"
      return 1
    fi
  fi

  # Check if cluster exists
  cluster_exists=$(echo "$cluster_json" | $VKDR_JQ -r --arg name "$CLUSTER_NAME" '.[] | select(.name == $name) | .name // empty')

  if [ -z "$cluster_exists" ]; then
    if [ "$VKDR_ENV_JSON" == "true" ]; then
      echo '{"cluster":"'"$CLUSTER_NAME"'","exists":false,"k3d_available":true,"status":"NOT_READY"}'
      return 0  # JSON mode always succeeds - status is in the output
    else
      boldError "Cluster '$CLUSTER_NAME' does not exist"
      info "Run 'vkdr infra start' to create the cluster"
      return 1
    fi
  fi

  # Get server counts
  servers_count=$(echo "$cluster_json" | $VKDR_JQ -r --arg name "$CLUSTER_NAME" '.[] | select(.name == $name) | .serversCount')
  servers_running=$(echo "$cluster_json" | $VKDR_JQ -r --arg name "$CLUSTER_NAME" '.[] | select(.name == $name) | .serversRunning')

  # Test API server
  api_server_ok="false"
  if $VKDR_KUBECTL cluster-info &>/dev/null; then
    api_server_ok="true"
  fi

  # Determine overall status
  local status="NOT_READY"
  if [ "$servers_running" -eq "$servers_count" ] && [ "$servers_running" -gt 0 ] && [ "$api_server_ok" == "true" ]; then
    status="READY"
  elif [ "$servers_running" -gt 0 ]; then
    status="DEGRADED"
  fi

  if [ "$VKDR_ENV_JSON" == "true" ]; then
    echo '{"cluster":"'"$CLUSTER_NAME"'","exists":true,"k3d_available":true,"servers_count":'"$servers_count"',"servers_running":'"$servers_running"',"api_server_reachable":'"$api_server_ok"',"status":"'"$status"'"}'
  else
    bold "=============================="
    boldInfo "VKDR Cluster Status"
    bold "=============================="
    notice "Cluster:          $CLUSTER_NAME"
    notice "Servers:          $servers_running/$servers_count running"
    if [ "$api_server_ok" == "true" ]; then
      info "API Server:       reachable"
    else
      error "API Server:       not reachable"
    fi
    bold "------------------------------"
    if [ "$status" == "READY" ]; then
      boldInfo "Status:           READY"
    elif [ "$status" == "DEGRADED" ]; then
      boldWarn "Status:           DEGRADED"
    else
      boldError "Status:           NOT_READY"
    fi
    bold "=============================="
  fi

  if [ "$VKDR_ENV_JSON" == "true" ]; then
    return 0  # JSON mode always succeeds - status is in the output
  elif [ "$status" == "READY" ]; then
    return 0
  else
    return 1
  fi
}

checkClusterStatus
