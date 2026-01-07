#!/usr/bin/env bats
# remove.bats - Tests for: vkdr grafana-cloud remove
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

  if ! $VKDR_HELM list -n vkdr | grep -q "^grafana-cloud"; then
    vkdr grafana-cloud install --token "test-token-for-remove"
    wait_for_helm_release "vkdr" "grafana-cloud" 180
  fi
}

teardown_file() {
  helm_delete_if_exists "vkdr" "grafana-cloud" || true
}

# ============================================================================
# Prerequisite Tests
# ============================================================================

@test "prerequisite: grafana-cloud is installed" {
  run $VKDR_HELM list -n vkdr -q
  assert_output --partial "grafana-cloud"
}

# ============================================================================
# Removal Tests
# ============================================================================

@test "grafana-cloud remove: command succeeds" {
  run vkdr grafana-cloud remove
  assert_success
}

@test "grafana-cloud remove: helm release is deleted" {
  sleep 5
  run $VKDR_HELM list -n vkdr -q
  refute_output --partial "grafana-cloud"
}
