#!/usr/bin/env bats
# remove.bats - Tests for: vkdr openldap remove
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

  if ! $VKDR_HELM list -n vkdr | grep -q "^openldap"; then
    vkdr openldap install --admin-user admin --admin-password admin123
    wait_for_helm_release "vkdr" "openldap" 180
  fi
}

teardown_file() {
  helm_delete_if_exists "vkdr" "openldap" || true
  # Clean up PVC if exists
  $VKDR_KUBECTL delete pvc data-openldap-0 -n vkdr --ignore-not-found=true 2>/dev/null || true
}

# ============================================================================
# Prerequisite Tests
# ============================================================================

@test "prerequisite: openldap is installed" {
  run $VKDR_HELM list -n vkdr -q
  assert_output --partial "openldap"
}

# ============================================================================
# Removal Tests
# ============================================================================

@test "openldap remove: command succeeds" {
  run vkdr openldap remove
  assert_success
}

@test "openldap remove: helm release is deleted" {
  sleep 5
  run $VKDR_HELM list -n vkdr -q
  refute_output --partial "openldap"
}

@test "openldap remove: statefulset is deleted" {
  local max_wait=60
  local waited=0
  while [ $waited -lt $max_wait ]; do
    if ! $VKDR_KUBECTL get statefulset openldap -n vkdr 2>/dev/null; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL get statefulset openldap -n vkdr 2>&1
  assert_failure
}
