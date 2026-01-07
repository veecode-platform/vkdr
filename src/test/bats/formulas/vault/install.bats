#!/usr/bin/env bats
# install.bats - Tests for: vkdr vault install
#
# Tests validate HashiCorp Vault installation.
# NOTE: Vault tests are tolerant - some may be skipped if vault has issues.
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

  # Clean up any existing vault installation
  helm_delete_if_exists "vkdr" "vault" || true
  $VKDR_KUBECTL delete secret vault-keys -n vkdr --ignore-not-found=true 2>/dev/null || true
  sleep 3
}

teardown_file() {
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    helm_delete_if_exists "vkdr" "vault" || true
    $VKDR_KUBECTL delete secret vault-keys -n vkdr --ignore-not-found=true 2>/dev/null || true
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
# Installation Tests (Dev Mode - simplest)
# ============================================================================

@test "vault install: dev mode installation" {
  run vkdr vault install --dev --dev-token root
  assert_success

  run wait_for_helm_release "vkdr" "vault" 180
  assert_success
}

@test "vault install: vault pod is running" {
  run wait_for_pods "vkdr" "app.kubernetes.io/name=vault" 120
  assert_success
}

@test "vault install: vault service exists" {
  run $VKDR_KUBECTL get service vault -n vkdr
  assert_success
}

@test "vault install: vault-ui service exists" {
  run $VKDR_KUBECTL get service vault-ui -n vkdr
  assert_success
}

@test "vault install: dev mode creates vault-keys secret" {
  run $VKDR_KUBECTL get secret vault-keys -n vkdr
  assert_success
}

@test "vault install: ingress is created" {
  run $VKDR_KUBECTL get ingress vault -n vkdr
  assert_success

  run $VKDR_KUBECTL get ingress vault -n vkdr -o jsonpath='{.spec.rules[0].host}'
  assert_output "vault.localhost"
}

# ============================================================================
# Explain Command Tests
# ============================================================================

@test "vault explain: shows documentation" {
  run vkdr vault explain
  assert_success
  assert_output --partial "Vault"
}

# ============================================================================
# Custom Domain Tests
# ============================================================================

@test "vault install: custom domain" {
  helm_delete_if_exists "vkdr" "vault" || true
  $VKDR_KUBECTL delete secret vault-keys -n vkdr --ignore-not-found=true 2>/dev/null || true
  sleep 5

  run vkdr vault install --dev --dev-token root --domain example.com
  assert_success

  run wait_for_pods "vkdr" "app.kubernetes.io/name=vault" 120
  assert_success

  run $VKDR_KUBECTL get ingress vault -n vkdr -o jsonpath='{.spec.rules[0].host}'
  assert_output "vault.example.com"
}
