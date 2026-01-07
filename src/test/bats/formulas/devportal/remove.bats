#!/usr/bin/env bats
# remove.bats - Tests for: vkdr devportal remove
#
# PREREQUISITES:
#   - VKDR tools installed (vkdr init)
#   - VKDR k3d cluster running (vkdr infra up)

load '../../helpers/common'

DEVPORTAL_NAMESPACE="platform"

# ============================================================================
# Setup & Teardown
# ============================================================================

setup_file() {
  load_vkdr
  configure_detik "$DEVPORTAL_NAMESPACE"

  if ! require_vkdr_cluster; then
    skip "VKDR cluster not available"
  fi

  # Ensure devportal is installed before removal tests
  if ! $VKDR_HELM list -n $DEVPORTAL_NAMESPACE | grep -q "^veecode-devportal"; then
    vkdr devportal install
    wait_for_helm_release "$DEVPORTAL_NAMESPACE" "veecode-devportal" 300
  fi
}

teardown_file() {
  $VKDR_HELM delete veecode-devportal -n $DEVPORTAL_NAMESPACE 2>/dev/null || true
  $VKDR_KUBECTL delete secret backstage-secrets -n $DEVPORTAL_NAMESPACE --ignore-not-found=true 2>/dev/null || true
}

# ============================================================================
# Prerequisite Tests
# ============================================================================

@test "prerequisite: devportal is installed" {
  run $VKDR_HELM list -n $DEVPORTAL_NAMESPACE -q
  assert_output --partial "veecode-devportal"
}

# ============================================================================
# Removal Tests
# ============================================================================

@test "devportal remove: command succeeds" {
  run vkdr devportal remove
  assert_success
}

@test "devportal remove: helm release is deleted" {
  sleep 5
  run $VKDR_HELM list -n $DEVPORTAL_NAMESPACE -q
  refute_output --partial "veecode-devportal"
}

@test "devportal remove: deployment is deleted" {
  local max_wait=60
  local waited=0
  while [ $waited -lt $max_wait ]; do
    if ! $VKDR_KUBECTL get deployment -n $DEVPORTAL_NAMESPACE -l app.kubernetes.io/name=backstage 2>/dev/null | grep -q "backstage"; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL get deployment -n $DEVPORTAL_NAMESPACE -l app.kubernetes.io/name=backstage 2>&1
  refute_output --partial "backstage"
}
