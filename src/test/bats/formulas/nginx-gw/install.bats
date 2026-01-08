#!/usr/bin/env bats
# install.bats - Tests for: vkdr nginx-gw install
#
# Tests validate NGINX Gateway Fabric installation.
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
  configure_detik "nginx-gateway"

  if ! require_vkdr_cluster; then
    skip "VKDR cluster not available"
  fi

  # Clean up any existing nginx-gateway installation
  helm_delete_if_exists "nginx-gateway" "nginx-gateway" || true
  sleep 3
}

teardown_file() {
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    helm_delete_if_exists "nginx-gateway" "nginx-gateway" || true
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

@test "nginx-gw install: default installation" {
  run vkdr nginx-gw install
  assert_success

  run wait_for_helm_release "nginx-gateway" "nginx-gateway" 180
  assert_success
}

@test "nginx-gw install: controller deployment is available" {
  run wait_for_deployment "nginx-gateway" "nginx-gateway-nginx-gateway-fabric" 180
  assert_success
}

@test "nginx-gw install: controller pods are running" {
  run wait_for_pods "nginx-gateway" "app.kubernetes.io/instance=nginx-gateway" 120
  assert_success
}

@test "nginx-gw install: controller service exists" {
  run $VKDR_KUBECTL get service nginx-gateway-nginx-gateway-fabric -n nginx-gateway
  assert_success
}

@test "nginx-gw install: gatewayclass nginx is created" {
  run $VKDR_KUBECTL get gatewayclass nginx
  assert_success
}

@test "nginx-gw install: Gateway API CRDs are installed" {
  run $VKDR_KUBECTL get crd gateways.gateway.networking.k8s.io
  assert_success

  run $VKDR_KUBECTL get crd httproutes.gateway.networking.k8s.io
  assert_success
}

@test "nginx-gw install: default gateway is created" {
  run $VKDR_KUBECTL get gateway nginx -n nginx-gateway
  assert_success
}
