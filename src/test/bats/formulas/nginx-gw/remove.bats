#!/usr/bin/env bats
# remove.bats - Tests for: vkdr nginx-gw remove
#
# PREREQUISITES:
#   - VKDR tools installed (vkdr init)
#   - VKDR k3d cluster running (vkdr infra up)

load '../../helpers/common'

# ============================================================================
# Setup & Teardown
# ============================================================================

setup_file() {
  load_vkdr
  configure_detik "nginx-gateway"

  if ! require_vkdr_cluster; then
    skip "VKDR cluster not available"
  fi

  # Ensure nginx-gateway is installed before testing removal
  if ! $VKDR_HELM list -n nginx-gateway | grep -q "nginx-gateway"; then
    vkdr nginx-gw install
    wait_for_deployment "nginx-gateway" "nginx-gateway-nginx-gateway-fabric" 180
  fi
}

teardown_file() {
  helm_delete_if_exists "nginx-gateway" "nginx-gateway" || true
}

# ============================================================================
# Prerequisite Tests
# ============================================================================

@test "prerequisite: nginx-gateway is installed" {
  run $VKDR_KUBECTL get deployment nginx-gateway-nginx-gateway-fabric -n nginx-gateway
  assert_success
}

# ============================================================================
# Removal Tests
# ============================================================================

@test "nginx-gw remove: command succeeds" {
  run vkdr nginx-gw remove
  assert_success
}

@test "nginx-gw remove: helm release is deleted" {
  sleep 5
  run $VKDR_HELM list -n nginx-gateway -q
  refute_output --partial "nginx-gateway"
}

@test "nginx-gw remove: deployment is deleted" {
  local max_wait=60
  local waited=0
  while [ $waited -lt $max_wait ]; do
    if ! $VKDR_KUBECTL get deployment nginx-gateway-nginx-gateway-fabric -n nginx-gateway 2>/dev/null; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL get deployment nginx-gateway-nginx-gateway-fabric -n nginx-gateway 2>&1
  assert_failure
}

@test "nginx-gw remove: pods are terminated" {
  local max_wait=60
  local waited=0
  while [ $waited -lt $max_wait ]; do
    local pod_count=$($VKDR_KUBECTL get pods -n nginx-gateway -l app.kubernetes.io/instance=nginx-gateway --no-headers 2>/dev/null | grep -v "No resources" | wc -l)
    if [ "$pod_count" -eq 0 ]; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL get pods -n nginx-gateway -l app.kubernetes.io/instance=nginx-gateway --no-headers 2>&1
  [[ -z "$output" ]] || [[ "$output" == *"No resources"* ]]
}
