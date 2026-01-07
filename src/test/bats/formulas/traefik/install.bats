#!/usr/bin/env bats
# install.bats - Tests for: vkdr traefik install
#
# Tests validate Traefik Ingress Controller installation.
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

  # Clean up any existing traefik installation
  helm_delete_if_exists "default" "traefik" || true
  sleep 3
}

teardown_file() {
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    helm_delete_if_exists "default" "traefik" || true
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

@test "traefik install: default installation" {
  run vkdr traefik install
  assert_success

  run wait_for_helm_release "default" "traefik" 180
  assert_success
}

@test "traefik install: deployment is available" {
  run wait_for_deployment "default" "traefik" 180
  assert_success
}

@test "traefik install: pods are running" {
  run wait_for_pods "default" "app.kubernetes.io/name=traefik" 120
  assert_success
}

@test "traefik install: service exists" {
  run $VKDR_KUBECTL get service traefik -n default
  assert_success
}

@test "traefik install: ingressclass traefik is created" {
  run $VKDR_KUBECTL get ingressclass traefik
  assert_success
}

# ============================================================================
# Configuration Tests
# ============================================================================

@test "traefik install: custom domain" {
  helm_delete_if_exists "default" "traefik" || true
  sleep 5

  run vkdr traefik install --domain example.com
  assert_success

  run wait_for_deployment "default" "traefik" 180
  assert_success
}

@test "traefik install: as default ingress controller" {
  helm_delete_if_exists "default" "traefik" || true
  sleep 5

  run vkdr traefik install --default-ic
  assert_success

  run wait_for_deployment "default" "traefik" 180
  assert_success

  # Check if traefik is the default ingress class
  run $VKDR_KUBECTL get ingressclass traefik -o jsonpath='{.metadata.annotations.ingressclass\.kubernetes\.io/is-default-class}'
  assert_output "true"
}

# ============================================================================
# Explain Command Tests
# ============================================================================

@test "traefik explain: shows documentation" {
  run vkdr traefik explain
  assert_success
  # Should show traefik documentation
  assert_output --partial "Traefik"
}
