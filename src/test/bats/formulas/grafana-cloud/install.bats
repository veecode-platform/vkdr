#!/usr/bin/env bats
# install.bats - Tests for: vkdr grafana-cloud install
#
# Tests validate Grafana Cloud k8s-monitoring installation.
# NOTE: Requires a valid Grafana Cloud token for full functionality.
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

  helm_delete_if_exists "vkdr" "grafana-cloud" || true
  sleep 3
}

teardown_file() {
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    helm_delete_if_exists "vkdr" "grafana-cloud" || true
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

@test "grafana-cloud install: installs with test token" {
  # Using a dummy token for installation testing
  # Real monitoring functionality requires valid Grafana Cloud credentials
  run vkdr grafana-cloud install --token "test-token-for-install"
  assert_success

  run wait_for_helm_release "vkdr" "grafana-cloud" 180
  assert_success
}

@test "grafana-cloud install: alloy deployment is created" {
  # k8s-monitoring chart creates alloy (formerly grafana-agent) pods
  local max_wait=120
  local waited=0
  while [ $waited -lt $max_wait ]; do
    if $VKDR_KUBECTL get deployment -n vkdr -l app.kubernetes.io/name=alloy 2>/dev/null | grep -q "alloy"; then
      break
    fi
    sleep 10
    waited=$((waited + 10))
  done

  run $VKDR_KUBECTL get deployment -n vkdr -l app.kubernetes.io/name=alloy
  assert_success
}

@test "grafana-cloud install: helm release exists" {
  run $VKDR_HELM list -n vkdr -q
  assert_output --partial "grafana-cloud"
}
