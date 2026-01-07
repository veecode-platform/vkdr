#!/usr/bin/env bats
# remove.bats - Tests for: vkdr minio remove
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

  if ! $VKDR_HELM list -n vkdr | grep -q "^minio"; then
    vkdr minio install --admin minio123
    wait_for_deployment "vkdr" "minio" 180
  fi
}

teardown_file() {
  helm_delete_if_exists "vkdr" "minio" || true
}

# ============================================================================
# Prerequisite Tests
# ============================================================================

@test "prerequisite: minio is installed" {
  run $VKDR_KUBECTL get deployment minio -n vkdr
  assert_success
}

# ============================================================================
# Removal Tests
# ============================================================================

@test "minio remove: command succeeds" {
  run vkdr minio remove
  assert_success
}

@test "minio remove: helm release is deleted" {
  sleep 5
  run $VKDR_HELM list -n vkdr -q
  refute_output --partial "minio"
}

@test "minio remove: deployment is deleted" {
  local max_wait=60
  local waited=0
  while [ $waited -lt $max_wait ]; do
    if ! $VKDR_KUBECTL get deployment minio -n vkdr 2>/dev/null; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL get deployment minio -n vkdr 2>&1
  assert_failure
}
