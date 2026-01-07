#!/usr/bin/env bats
# remove.bats - Tests for: vkdr postgres remove
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
  configure_detik "vkdr"

  if ! require_vkdr_cluster; then
    skip "VKDR cluster not available"
  fi

  # Ensure postgres is installed before testing removal
  if ! $VKDR_KUBECTL get cluster vkdr-pg-cluster -n vkdr &>/dev/null; then
    vkdr postgres install --wait
  fi
}

teardown_file() {
  # Final cleanup
  $VKDR_KUBECTL delete cluster vkdr-pg-cluster -n vkdr --ignore-not-found=true 2>/dev/null || true
}

# ============================================================================
# Prerequisite Tests
# ============================================================================

@test "prerequisite: postgres cluster exists" {
  run $VKDR_KUBECTL get cluster vkdr-pg-cluster -n vkdr
  assert_success
}

# ============================================================================
# Removal Tests
# ============================================================================

@test "postgres remove: command succeeds" {
  run vkdr postgres remove
  assert_success
}

@test "postgres remove: cluster is deleted" {
  sleep 5
  run $VKDR_KUBECTL get cluster vkdr-pg-cluster -n vkdr 2>&1
  assert_failure
}

@test "postgres remove: pods are terminated" {
  local max_wait=60
  local waited=0
  while [ $waited -lt $max_wait ]; do
    local pod_count=$($VKDR_KUBECTL get pods -n vkdr -l cnpg.io/cluster=vkdr-pg-cluster --no-headers 2>/dev/null | grep -v "No resources" | wc -l)
    if [ "$pod_count" -eq 0 ]; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL get pods -n vkdr -l cnpg.io/cluster=vkdr-pg-cluster --no-headers 2>&1
  [[ -z "$output" ]] || [[ "$output" == *"No resources"* ]]
}

@test "postgres remove: services are deleted" {
  run $VKDR_KUBECTL get service vkdr-pg-cluster-rw -n vkdr 2>&1
  assert_failure
}
