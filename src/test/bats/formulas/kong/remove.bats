#!/usr/bin/env bats
# remove.bats - Tests for: vkdr kong remove
#
# These tests validate the Kong API Gateway removal process.
#
# PREREQUISITES:
#   - VKDR tools installed (vkdr init)
#   - VKDR k3d cluster running (vkdr infra up)

load '../../helpers/common'

# ============================================================================
# Setup & Teardown
# ============================================================================

setup_file() {
  # Load VKDR environment
  load_vkdr

  # Kong runs in vkdr namespace
  configure_detik "vkdr"

  # Require VKDR cluster - skip all tests if not available
  if ! require_vkdr_cluster; then
    skip "VKDR cluster (vkdr-local) not available. Run 'vkdr infra up' first."
  fi

  # Ensure kong is installed before testing removal
  helm_delete_if_exists "vkdr" "kong" || true
  sleep 3

  # Install kong in dbless mode for removal tests
  vkdr kong install
  wait_for_helm_release "vkdr" "kong" 180
  wait_for_deployment "vkdr" "kong-kong" 180
}

teardown_file() {
  # Final cleanup
  helm_delete_if_exists "vkdr" "kong" || true
}

# ============================================================================
# Prerequisite Tests
# ============================================================================

# @test: Verify Kong is installed before removal tests
@test "prerequisite: kong is installed" {
  run $VKDR_KUBECTL get deployment kong-kong -n vkdr
  assert_success
}

# ============================================================================
# Removal Tests
# ============================================================================

# @doc: Remove Kong installation
# @example: vkdr kong remove
@test "kong remove: command succeeds" {
  run vkdr kong remove
  assert_success
}

# @doc: Verify helm release is removed
@test "kong remove: helm release is deleted" {
  # Give helm time to process deletion
  sleep 5

  run $VKDR_HELM list -n vkdr -q
  refute_output --partial "kong"
}

# @doc: Verify Kong deployment is removed
@test "kong remove: deployment is deleted" {
  # Wait for deployment to be gone
  local max_wait=60
  local waited=0
  while [ $waited -lt $max_wait ]; do
    if ! $VKDR_KUBECTL get deployment kong-kong -n vkdr 2>/dev/null; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL get deployment kong-kong -n vkdr 2>&1
  assert_failure
}

# @doc: Verify Kong services are removed
@test "kong remove: services are deleted" {
  run $VKDR_KUBECTL get service kong-kong-proxy -n vkdr 2>&1
  assert_failure
}

# @doc: Verify Kong manager ingress is removed
@test "kong remove: manager ingress is deleted" {
  run $VKDR_KUBECTL get ingress kong-kong-manager -n vkdr 2>&1
  assert_failure
}

# @doc: Verify Kong pods are terminated
@test "kong remove: pods are terminated" {
  # Wait for pods to terminate
  local max_wait=90
  local waited=0
  while [ $waited -lt $max_wait ]; do
    local pod_count=$($VKDR_KUBECTL get pods -n vkdr -l app.kubernetes.io/instance=kong --no-headers 2>/dev/null | grep -v "No resources" | wc -l)
    if [ "$pod_count" -eq 0 ]; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  # Verify no kong pods exist (output is empty or "No resources found")
  run $VKDR_KUBECTL get pods -n vkdr -l app.kubernetes.io/instance=kong --no-headers 2>&1
  [[ -z "$output" ]] || [[ "$output" == *"No resources"* ]]
}
