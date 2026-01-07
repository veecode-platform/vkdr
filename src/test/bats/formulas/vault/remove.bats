#!/usr/bin/env bats
# remove.bats - Tests for: vkdr vault remove
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

  # Ensure vault is installed before testing removal
  if ! $VKDR_HELM list -n vkdr | grep -q "^vault"; then
    vkdr vault install --dev --dev-root-token root
    wait_for_pods "vkdr" "app.kubernetes.io/name=vault" 120
  fi
}

teardown_file() {
  helm_delete_if_exists "vkdr" "vault" || true
  $VKDR_KUBECTL delete secret vault-keys -n vkdr --ignore-not-found=true 2>/dev/null || true
}

# ============================================================================
# Prerequisite Tests
# ============================================================================

@test "prerequisite: vault is installed" {
  run $VKDR_KUBECTL get pod -n vkdr -l app.kubernetes.io/name=vault
  assert_success
}

# ============================================================================
# Removal Tests
# ============================================================================

@test "vault remove: command succeeds" {
  run vkdr vault remove
  assert_success
}

@test "vault remove: helm release is deleted" {
  sleep 5
  run $VKDR_HELM list -n vkdr -q
  refute_output --partial "vault"
}

@test "vault remove: pods are terminated" {
  local max_wait=60
  local waited=0
  while [ $waited -lt $max_wait ]; do
    local pod_count=$($VKDR_KUBECTL get pods -n vkdr -l app.kubernetes.io/name=vault --no-headers 2>/dev/null | grep -v "No resources" | wc -l)
    if [ "$pod_count" -eq 0 ]; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL get pods -n vkdr -l app.kubernetes.io/name=vault --no-headers 2>&1
  [[ -z "$output" ]] || [[ "$output" == *"No resources"* ]]
}
