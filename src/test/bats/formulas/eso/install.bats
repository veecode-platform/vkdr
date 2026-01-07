#!/usr/bin/env bats
# install.bats - Tests for: vkdr eso install
#
# Tests validate External Secrets Operator installation.
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

  helm_delete_if_exists "vkdr" "external-secrets" || true
  sleep 3
}

teardown_file() {
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    helm_delete_if_exists "vkdr" "external-secrets" || true
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

@test "eso install: installs external secrets operator" {
  run vkdr eso install
  assert_success

  run wait_for_helm_release "vkdr" "external-secrets" 180
  assert_success
}

@test "eso install: deployment is available" {
  run wait_for_deployment "vkdr" "external-secrets" 180
  assert_success
}

@test "eso install: webhook deployment is available" {
  run wait_for_deployment "vkdr" "external-secrets-webhook" 180
  assert_success
}

@test "eso install: cert-controller deployment is available" {
  run wait_for_deployment "vkdr" "external-secrets-cert-controller" 180
  assert_success
}

@test "eso install: CRDs are installed" {
  run $VKDR_KUBECTL get crd externalsecrets.external-secrets.io
  assert_success

  run $VKDR_KUBECTL get crd secretstores.external-secrets.io
  assert_success
}
