#!/usr/bin/env bats
# remove.bats - Tests for: vkdr traefik remove
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
  configure_detik "default"

  if ! require_vkdr_cluster; then
    skip "VKDR cluster not available"
  fi

  # Ensure traefik is installed before testing removal
  if ! $VKDR_HELM list -n default | grep -q "^traefik"; then
    vkdr traefik install
    wait_for_deployment "default" "traefik" 180
  fi
}

teardown_file() {
  helm_delete_if_exists "default" "traefik" || true
}

# ============================================================================
# Prerequisite Tests
# ============================================================================

@test "prerequisite: traefik is installed" {
  run $VKDR_KUBECTL get deployment traefik -n default
  assert_success
}

# ============================================================================
# Removal Tests
# ============================================================================

@test "traefik remove: command succeeds" {
  run vkdr traefik remove
  assert_success
}

@test "traefik remove: helm release is deleted" {
  sleep 5
  run $VKDR_HELM list -n default -q
  refute_output --partial "traefik"
}

@test "traefik remove: deployment is deleted" {
  local max_wait=60
  local waited=0
  while [ $waited -lt $max_wait ]; do
    if ! $VKDR_KUBECTL get deployment traefik -n default 2>/dev/null; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL get deployment traefik -n default 2>&1
  assert_failure
}
