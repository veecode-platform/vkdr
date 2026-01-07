#!/usr/bin/env bats
# remove.bats - Tests for: vkdr nginx remove
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

  # Ensure nginx is installed before testing removal
  if ! $VKDR_HELM list -n default | grep -q "ingress-nginx"; then
    vkdr nginx install
    wait_for_deployment "default" "ingress-nginx-controller" 180
  fi
}

teardown_file() {
  helm_delete_if_exists "default" "ingress-nginx" || true
}

# ============================================================================
# Prerequisite Tests
# ============================================================================

@test "prerequisite: nginx is installed" {
  run $VKDR_KUBECTL get deployment ingress-nginx-controller -n default
  assert_success
}

# ============================================================================
# Removal Tests
# ============================================================================

@test "nginx remove: command succeeds" {
  run vkdr nginx remove
  assert_success
}

@test "nginx remove: helm release is deleted" {
  sleep 5
  run $VKDR_HELM list -n default -q
  refute_output --partial "ingress-nginx"
}

@test "nginx remove: deployment is deleted" {
  local max_wait=60
  local waited=0
  while [ $waited -lt $max_wait ]; do
    if ! $VKDR_KUBECTL get deployment ingress-nginx-controller -n default 2>/dev/null; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL get deployment ingress-nginx-controller -n default 2>&1
  assert_failure
}

@test "nginx remove: pods are terminated" {
  local max_wait=60
  local waited=0
  while [ $waited -lt $max_wait ]; do
    local pod_count=$($VKDR_KUBECTL get pods -n default -l app.kubernetes.io/component=controller --no-headers 2>/dev/null | grep -v "No resources" | wc -l)
    if [ "$pod_count" -eq 0 ]; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL get pods -n default -l app.kubernetes.io/component=controller --no-headers 2>&1
  [[ -z "$output" ]] || [[ "$output" == *"No resources"* ]]
}
