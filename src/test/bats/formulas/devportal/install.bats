#!/usr/bin/env bats
# install.bats - Tests for: vkdr devportal install
#
# Tests validate DevPortal (Backstage) installation.
# NOTE: DevPortal requires kong as ingress controller (auto-installed).
# NOTE: Full GitHub integration tests require valid credentials.
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

  # Clean up any existing devportal installation
  $VKDR_HELM delete veecode-devportal -n $DEVPORTAL_NAMESPACE 2>/dev/null || true
  $VKDR_KUBECTL delete secret backstage-secrets -n $DEVPORTAL_NAMESPACE --ignore-not-found=true 2>/dev/null || true
  sleep 3
}

teardown_file() {
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    $VKDR_HELM delete veecode-devportal -n $DEVPORTAL_NAMESPACE 2>/dev/null || true
    $VKDR_KUBECTL delete secret backstage-secrets -n $DEVPORTAL_NAMESPACE --ignore-not-found=true 2>/dev/null || true
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

@test "devportal install: installs devportal (local profile)" {
  # Local profile requires no GitHub credentials
  run vkdr devportal install
  assert_success
}

@test "devportal install: namespace is created" {
  run $VKDR_KUBECTL get namespace $DEVPORTAL_NAMESPACE
  assert_success
}

@test "devportal install: helm release exists" {
  run wait_for_helm_release "$DEVPORTAL_NAMESPACE" "veecode-devportal" 300
  assert_success
}

@test "devportal install: backstage deployment is created" {
  local max_wait=300
  local waited=0
  while [ $waited -lt $max_wait ]; do
    if $VKDR_KUBECTL get deployment -n $DEVPORTAL_NAMESPACE -l app.kubernetes.io/name=backstage 2>/dev/null | grep -q "backstage"; then
      break
    fi
    sleep 15
    waited=$((waited + 15))
  done

  run $VKDR_KUBECTL get deployment -n $DEVPORTAL_NAMESPACE -l app.kubernetes.io/name=backstage
  assert_success
}

@test "devportal install: backstage secrets are created" {
  run $VKDR_KUBECTL get secret backstage-secrets -n $DEVPORTAL_NAMESPACE
  assert_success
}

@test "devportal install: kong ingress is installed" {
  # DevPortal auto-installs kong as ingress controller
  run $VKDR_HELM list -n vkdr -q
  assert_output --partial "kong"
}

@test "devportal install: ingress is created" {
  run $VKDR_KUBECTL get ingress -n $DEVPORTAL_NAMESPACE
  assert_success
}
