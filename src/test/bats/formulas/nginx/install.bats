#!/usr/bin/env bats
# install.bats - Tests for: vkdr nginx install
#
# Tests validate Nginx Ingress Controller installation.
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

  # Clean up any existing nginx installation
  helm_delete_if_exists "default" "ingress-nginx" || true
  sleep 3
}

teardown_file() {
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    helm_delete_if_exists "default" "ingress-nginx" || true
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

@test "nginx install: default installation" {
  run vkdr nginx install
  assert_success

  run wait_for_helm_release "default" "ingress-nginx" 180
  assert_success
}

@test "nginx install: controller deployment is available" {
  run wait_for_deployment "default" "ingress-nginx-controller" 180
  assert_success
}

@test "nginx install: controller pods are running" {
  run wait_for_pods "default" "app.kubernetes.io/component=controller" 120
  assert_success
}

@test "nginx install: controller service exists" {
  run $VKDR_KUBECTL get service ingress-nginx-controller -n default
  assert_success
}

@test "nginx install: ingressclass nginx is created" {
  run $VKDR_KUBECTL get ingressclass nginx
  assert_success
}

# ============================================================================
# Configuration Tests
# ============================================================================

@test "nginx install: as default ingress controller" {
  # Clean previous
  helm_delete_if_exists "default" "ingress-nginx" || true
  sleep 5

  run vkdr nginx install --default
  assert_success

  run wait_for_deployment "default" "ingress-nginx-controller" 180
  assert_success

  # Check if nginx is the default ingress class
  run $VKDR_KUBECTL get ingressclass nginx -o jsonpath='{.metadata.annotations.ingressclass\.kubernetes\.io/is-default-class}'
  assert_output "true"
}
