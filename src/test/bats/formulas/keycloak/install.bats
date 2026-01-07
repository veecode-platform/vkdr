#!/usr/bin/env bats
# install.bats - Tests for: vkdr keycloak install
#
# Tests validate Keycloak authentication server installation.
# NOTE: Keycloak requires postgres, which will be auto-installed.
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

  # Clean up any existing keycloak installation
  $VKDR_KUBECTL delete keycloak vkdr-keycloak -n $KEYCLOAK_NAMESPACE --ignore-not-found=true 2>/dev/null || true
  $VKDR_KUBECTL delete secret vkdr-keycloak-bootstrap-admin-user -n $KEYCLOAK_NAMESPACE --ignore-not-found=true 2>/dev/null || true
  $VKDR_KUBECTL delete secret keycloak-db-secret -n $KEYCLOAK_NAMESPACE --ignore-not-found=true 2>/dev/null || true
  sleep 3
}

teardown_file() {
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    $VKDR_KUBECTL delete keycloak vkdr-keycloak -n $KEYCLOAK_NAMESPACE --ignore-not-found=true 2>/dev/null || true
    $VKDR_KUBECTL delete secret vkdr-keycloak-bootstrap-admin-user -n $KEYCLOAK_NAMESPACE --ignore-not-found=true 2>/dev/null || true
    $VKDR_KUBECTL delete secret keycloak-db-secret -n $KEYCLOAK_NAMESPACE --ignore-not-found=true 2>/dev/null || true
  fi
}

# ============================================================================
# Prerequisite Tests
# ============================================================================

@test "prerequisite: vkdr tools are installed" {
  run check_vkdr_tools
  assert_success
}

@test "prerequisite: vkdr cluster is running" {
  run check_vkdr_cluster
  assert_success
}

# ============================================================================
# Installation Tests
# ============================================================================

@test "keycloak install: installs keycloak with postgres" {
  run vkdr keycloak install --admin-user admin --admin-password admin123
  assert_success
}

@test "keycloak install: keycloak operator is running" {
  run $VKDR_KUBECTL get deployment keycloak-operator -n $KEYCLOAK_NAMESPACE
  assert_success

  run wait_for_deployment "$KEYCLOAK_NAMESPACE" "keycloak-operator" 180
  assert_success
}

@test "keycloak install: keycloak CR is created" {
  run $VKDR_KUBECTL get keycloak vkdr-keycloak -n $KEYCLOAK_NAMESPACE
  assert_success
}

@test "keycloak install: keycloak pods are running" {
  # Wait for keycloak statefulset pods
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

  run $VKDR_KUBECTL get pod -n $KEYCLOAK_NAMESPACE -l app=keycloak
  assert_success
  assert_output --partial "Running"
}

@test "keycloak install: admin secret is created" {
  run $VKDR_KUBECTL get secret vkdr-keycloak-bootstrap-admin-user -n $KEYCLOAK_NAMESPACE
  assert_success
}

@test "keycloak install: postgres database is created" {
  run $VKDR_KUBECTL get database vkdr-pg-cluster-keycloak -n vkdr
  assert_success
}

@test "keycloak install: database secret is created" {
  run $VKDR_KUBECTL get secret keycloak-db-secret -n $KEYCLOAK_NAMESPACE
  assert_success
}
