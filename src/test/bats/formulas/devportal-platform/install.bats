#!/usr/bin/env bats
# install.bats - Tests for: vkdr devportal-platform install (DevPortal V2)
#
# Validates the V2 (presets-based) install from the published
# veecode-devportal-platform Helm chart. Separate from the V1 devportal tests.
#
# PREREQUISITES:
#   - VKDR tools installed (vkdr init)
#   - VKDR k3d cluster running (vkdr infra up)

load '../../helpers/common'

DEVPORTAL_NAMESPACE="platform"
RELEASE="veecode-devportal-platform"
SECRET="devportal-platform-secrets"

# ============================================================================
# Setup & Teardown
# ============================================================================

setup_file() {
  load_vkdr
  configure_detik "$DEVPORTAL_NAMESPACE"

  if ! require_vkdr_cluster; then
    skip "VKDR cluster not available"
  fi

  $VKDR_HELM delete "$RELEASE" -n $DEVPORTAL_NAMESPACE 2>/dev/null || true
  $VKDR_KUBECTL delete secret "$SECRET" -n $DEVPORTAL_NAMESPACE --ignore-not-found=true 2>/dev/null || true
  sleep 3
}

teardown_file() {
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    $VKDR_HELM delete "$RELEASE" -n $DEVPORTAL_NAMESPACE 2>/dev/null || true
    $VKDR_KUBECTL delete secret "$SECRET" -n $DEVPORTAL_NAMESPACE --ignore-not-found=true 2>/dev/null || true
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

@test "devportal-platform install: installs DevPortal V2 (core presets, no credentials)" {
  # Default presets (recommended) require no credentials; installs with --wait.
  run vkdr devportal-platform install
  assert_success
}

@test "devportal-platform install: namespace is created" {
  run $VKDR_KUBECTL get namespace $DEVPORTAL_NAMESPACE
  assert_success
}

@test "devportal-platform install: helm release exists" {
  run wait_for_helm_release "$DEVPORTAL_NAMESPACE" "$RELEASE" 300
  assert_success
}

@test "devportal-platform install: deployment is created" {
  local max_wait=120
  local waited=0
  while [ $waited -lt $max_wait ]; do
    if $VKDR_KUBECTL get deployment -n $DEVPORTAL_NAMESPACE -l app.kubernetes.io/name=veecode-devportal-platform 2>/dev/null | grep -q "veecode-devportal-platform"; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL get deployment -n $DEVPORTAL_NAMESPACE -l app.kubernetes.io/name=veecode-devportal-platform
  assert_success
}

@test "devportal-platform install: credentials secret is created" {
  run $VKDR_KUBECTL get secret "$SECRET" -n $DEVPORTAL_NAMESPACE
  assert_success
}

@test "devportal-platform install: pod answers /healthcheck (200)" {
  # The install runs with --wait, so the pod should be Ready by now.
  local pod
  pod=$($VKDR_KUBECTL get pod -n $DEVPORTAL_NAMESPACE -l app.kubernetes.io/name=veecode-devportal-platform -o name | head -1)
  [ -n "$pod" ]
  run $VKDR_KUBECTL exec "$pod" -n $DEVPORTAL_NAMESPACE -c devportal -- curl -s -o /dev/null -w '%{http_code}' localhost:7007/healthcheck
  assert_output "200"
}

@test "devportal-platform install: kong ingress controller present" {
  run $VKDR_HELM list -n vkdr -q
  assert_output --partial "kong"
}

@test "devportal-platform install: ingress is created" {
  run $VKDR_KUBECTL get ingress -n $DEVPORTAL_NAMESPACE
  assert_success
}
