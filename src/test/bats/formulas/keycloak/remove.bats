#!/usr/bin/env bats
# remove.bats - Tests for: vkdr keycloak remove
#
# PREREQUISITES:
#   - VKDR tools installed (vkdr init)
#   - VKDR k3d cluster running (vkdr infra up)

load '../../helpers/common'

KEYCLOAK_NAMESPACE="keycloak"

# ============================================================================
# Setup & Teardown
# ============================================================================

setup_file() {
  load_vkdr
  configure_detik "$KEYCLOAK_NAMESPACE"

  if ! require_vkdr_cluster; then
    skip "VKDR cluster not available"
  fi

  # Ensure keycloak is installed before removal tests
  if ! $VKDR_KUBECTL get keycloak vkdr-keycloak -n $KEYCLOAK_NAMESPACE 2>/dev/null; then
    vkdr keycloak install --admin_user admin --admin_password admin123
    # Wait for keycloak to be ready
    local max_wait=300
    local waited=0
    while [ $waited -lt $max_wait ]; do
      local ready=$($VKDR_KUBECTL get pod -n $KEYCLOAK_NAMESPACE -l app=keycloak -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "")
      if [ "$ready" = "Running" ]; then
        break
      fi
      sleep 10
      waited=$((waited + 10))
    done
  fi
}

teardown_file() {
  # Clean up any remaining keycloak resources
  $VKDR_KUBECTL delete keycloak vkdr-keycloak -n $KEYCLOAK_NAMESPACE --ignore-not-found=true 2>/dev/null || true
  $VKDR_KUBECTL delete secret vkdr-keycloak-bootstrap-admin-user -n $KEYCLOAK_NAMESPACE --ignore-not-found=true 2>/dev/null || true
  $VKDR_KUBECTL delete secret keycloak-db-secret -n $KEYCLOAK_NAMESPACE --ignore-not-found=true 2>/dev/null || true
}

# ============================================================================
# Prerequisite Tests
# ============================================================================

@test "prerequisite: keycloak is installed" {
  run $VKDR_KUBECTL get keycloak vkdr-keycloak -n $KEYCLOAK_NAMESPACE
  assert_success
}

# ============================================================================
# Removal Tests
# ============================================================================

@test "keycloak remove: command succeeds" {
  run vkdr keycloak remove
  assert_success
}

@test "keycloak remove: keycloak CR is deleted" {
  local max_wait=60
  local waited=0
  while [ $waited -lt $max_wait ]; do
    if ! $VKDR_KUBECTL get keycloak vkdr-keycloak -n $KEYCLOAK_NAMESPACE 2>/dev/null; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL get keycloak vkdr-keycloak -n $KEYCLOAK_NAMESPACE 2>&1
  assert_failure
}

@test "keycloak remove: admin secret is deleted" {
  run $VKDR_KUBECTL get secret vkdr-keycloak-bootstrap-admin-user -n $KEYCLOAK_NAMESPACE 2>&1
  assert_failure
}

@test "keycloak remove: database secret is deleted" {
  run $VKDR_KUBECTL get secret keycloak-db-secret -n $KEYCLOAK_NAMESPACE 2>&1
  assert_failure
}
