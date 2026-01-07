#!/usr/bin/env bats
# install.bats - Tests for: vkdr whoami install
#
# These tests validate the whoami service installation and also serve
# as executable documentation for the explain command.
#
# PREREQUISITES:
#   - VKDR tools installed (vkdr init)
#   - VKDR k3d cluster running (vkdr infra up)

load '../../helpers/common'

# ============================================================================
# Setup & Teardown
# ============================================================================

setup_file() {
  # Load VKDR environment
  load_vkdr

  # Configure bats-detik for the vkdr namespace
  configure_detik "vkdr"

  # Require VKDR cluster - skip all tests if not available
  if ! require_vkdr_cluster; then
    skip "VKDR cluster (vkdr-local) not available. Run 'vkdr infra up' first."
  fi

  # Ensure clean state before tests
  helm_delete_if_exists "vkdr" "whoami" || true
  sleep 2
}

teardown_file() {
  # Cleanup unless VKDR_SKIP_TEARDOWN is set (for debugging)
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    helm_delete_if_exists "vkdr" "whoami" || true
  fi
}

# ============================================================================
# Prerequisite Tests
# ============================================================================

# @test: Verify VKDR tools are available
@test "prerequisite: vkdr tools are installed" {
  run check_vkdr_tools
  assert_success
}

# @test: Verify VKDR cluster is running
@test "prerequisite: vkdr cluster is running" {
  run check_vkdr_cluster
  assert_success
}

# ============================================================================
# Basic Installation Tests
# ============================================================================

# @doc: Install whoami with default settings (localhost domain)
# @example: vkdr whoami install
@test "whoami install: default localhost domain" {
  run vkdr whoami install
  assert_success

  # Wait for helm release to be deployed
  run wait_for_helm_release "vkdr" "whoami" 120
  assert_success
}

# @doc: Verify deployment is created and available
@test "whoami install: deployment becomes available" {
  # Wait for deployment to be available
  run wait_for_deployment "vkdr" "whoami" 120
  assert_success

  # Verify deployment exists with correct replicas
  run $VKDR_KUBECTL get deployment whoami -n vkdr -o jsonpath='{.spec.replicas}'
  assert_output "1"
}

# @doc: Verify whoami pod reaches running state
@test "whoami install: pod reaches running state" {
  # Wait for pods to be ready
  run wait_for_pods "vkdr" "app.kubernetes.io/name=whoami" 90
  assert_success
}

# @doc: Verify whoami service is created with correct port
@test "whoami install: service is created with port 80" {
  # Check service exists
  run $VKDR_KUBECTL get service whoami -n vkdr
  assert_success

  # Verify port configuration
  run $VKDR_KUBECTL get service whoami -n vkdr -o jsonpath='{.spec.ports[0].port}'
  assert_output "80"
}

# @doc: Verify service has endpoints
@test "whoami install: service has endpoints" {
  run wait_for_endpoints "vkdr" "whoami" 60
  assert_success
}

# @doc: Verify ingress is created with localhost host
@test "whoami install: ingress created with localhost host" {
  # Check ingress exists
  run $VKDR_KUBECTL get ingress whoami -n vkdr
  assert_success

  # Verify ingress host
  run $VKDR_KUBECTL get ingress whoami -n vkdr -o jsonpath='{.spec.rules[0].host}'
  assert_output "whoami.localhost"
}

# ============================================================================
# Custom Domain Tests
# ============================================================================

# @doc: Install whoami with custom domain
# @example: vkdr whoami install --domain example.com
@test "whoami install: custom domain configuration" {
  # Clean previous install
  helm_delete_if_exists "vkdr" "whoami" || true
  sleep 3

  run vkdr whoami install --domain example.com
  assert_success

  # Wait for deployment
  run wait_for_rollout "vkdr" "whoami" 120
  assert_success

  # Verify ingress has custom domain
  run $VKDR_KUBECTL get ingress whoami -n vkdr -o jsonpath='{.spec.rules[0].host}'
  assert_output "whoami.example.com"
}

# ============================================================================
# TLS/Secure Mode Tests
# ============================================================================

# @doc: Install whoami with TLS enabled
# @example: vkdr whoami install --domain example.com --secure
@test "whoami install: TLS configuration" {
  # Clean previous install
  helm_delete_if_exists "vkdr" "whoami" || true
  sleep 3

  run vkdr whoami install --domain example.com --secure
  assert_success

  # Wait for deployment
  run wait_for_rollout "vkdr" "whoami" 120
  assert_success

  # Verify TLS is configured on ingress
  run $VKDR_KUBECTL get ingress whoami -n vkdr -o jsonpath='{.spec.tls[0].hosts[0]}'
  assert_output "whoami.example.com"

  # Verify TLS secret name
  run $VKDR_KUBECTL get ingress whoami -n vkdr -o jsonpath='{.spec.tls[0].secretName}'
  assert_output "whoami-tls"
}

# ============================================================================
# Labels Tests
# ============================================================================

# @doc: Install whoami with custom labels
# @example: vkdr whoami install --label team=platform --label env=test
@test "whoami install: custom labels applied to deployment" {
  # Clean previous install
  helm_delete_if_exists "vkdr" "whoami" || true
  sleep 3

  run vkdr whoami install --label team=platform --label env=test
  assert_success

  # Wait for deployment
  run wait_for_rollout "vkdr" "whoami" 120
  assert_success

  # Verify labels on deployment
  run $VKDR_KUBECTL get deployment whoami -n vkdr -o jsonpath='{.metadata.labels.team}'
  assert_output "platform"

  run $VKDR_KUBECTL get deployment whoami -n vkdr -o jsonpath='{.metadata.labels.env}'
  assert_output "test"
}

# ============================================================================
# HTTP Response Tests (Optional)
# ============================================================================

# @doc: Verify whoami responds to HTTP requests via port-forward
@test "whoami install: service responds via port-forward" {
  # This test requires the service to be running
  run $VKDR_KUBECTL get svc whoami -n vkdr
  assert_success

  # Start port-forward in background
  $VKDR_KUBECTL port-forward svc/whoami -n vkdr 18080:80 &
  local pf_pid=$!
  sleep 3

  # Test HTTP response
  run curl -s -o /dev/null -w '%{http_code}' http://localhost:18080

  # Cleanup port-forward
  kill $pf_pid 2>/dev/null || true

  assert_output "200"
}
