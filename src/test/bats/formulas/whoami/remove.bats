#!/usr/bin/env bats
# remove.bats - Tests for: vkdr whoami remove
#
# These tests validate the whoami service removal.
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

  # Configure bats-detik for the vkdr namespace
  configure_detik "vkdr"

  # Require VKDR cluster - skip all tests if not available
  if ! require_vkdr_cluster; then
    skip "VKDR cluster (vkdr-local) not available. Run 'vkdr infra up' first."
  fi

  # Ensure whoami is installed before testing removal
  if ! helm_release_exists "vkdr" "whoami"; then
    vkdr whoami install
    wait_for_rollout "vkdr" "whoami" 120
  fi
}

teardown_file() {
  # Ensure cleanup even if tests fail
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    helm_delete_if_exists "vkdr" "whoami" || true
  fi
}

# ============================================================================
# Prerequisite Tests
# ============================================================================

# @test: Verify VKDR cluster is running
@test "prerequisite: vkdr cluster is running" {
  run check_vkdr_cluster
  assert_success
}

# ============================================================================
# Remove Tests
# ============================================================================

# @doc: Remove whoami service
# @example: vkdr whoami remove
@test "whoami remove: removes helm release" {
  # Verify whoami is installed
  run helm_release_exists "vkdr" "whoami"
  assert_success

  # Remove whoami
  run vkdr whoami remove
  assert_success
}

# @doc: Verify deployment is deleted after remove
@test "whoami remove: deployment is deleted" {
  # Give helm time to remove resources
  sleep 5

  # Verify deployment no longer exists
  run $VKDR_KUBECTL get deployment whoami -n vkdr 2>&1
  assert_failure
  assert_output --partial "not found"
}

# @doc: Verify service is deleted after remove
@test "whoami remove: service is deleted" {
  # Verify service no longer exists
  run $VKDR_KUBECTL get service whoami -n vkdr 2>&1
  assert_failure
  assert_output --partial "not found"
}

# @doc: Verify ingress is deleted after remove
@test "whoami remove: ingress is deleted" {
  # Verify ingress no longer exists
  run $VKDR_KUBECTL get ingress whoami -n vkdr 2>&1
  assert_failure
  assert_output --partial "not found"
}

# @doc: Verify helm release no longer exists
@test "whoami remove: helm release is gone" {
  run helm_release_exists "vkdr" "whoami"
  assert_failure
}

# ============================================================================
# Idempotency Tests
# ============================================================================

# @doc: Remove on already-removed service should fail gracefully
@test "whoami remove: idempotent on missing release" {
  # Ensure whoami is not installed
  helm_delete_if_exists "vkdr" "whoami" || true

  # Running remove again should fail (helm delete fails if not found)
  run vkdr whoami remove
  # We expect this to fail since there's nothing to remove
  assert_failure
}
