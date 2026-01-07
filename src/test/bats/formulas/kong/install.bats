#!/usr/bin/env bats
# install.bats - Tests for: vkdr kong install
#
# These tests validate the Kong API Gateway installation and serve
# as executable documentation for the explain command.
#
# PREREQUISITES:
#   - VKDR tools installed (vkdr init)
#   - VKDR k3d cluster running (vkdr infra up)
#
# NOTE: Tests focus on dbless mode (default) to avoid postgres dependency.
# Standard mode tests require postgres to be installed first.

load '../../helpers/common'

# ============================================================================
# Setup & Teardown
# ============================================================================

setup_file() {
  # Load VKDR environment
  load_vkdr

  # Kong runs in vkdr namespace
  configure_detik "vkdr"

  # Require VKDR cluster - skip all tests if not available
  if ! require_vkdr_cluster; then
    skip "VKDR cluster (vkdr-local) not available. Run 'vkdr infra up' first."
  fi

  # Ensure clean state before tests
  helm_delete_if_exists "vkdr" "kong" || true
  sleep 3
}

teardown_file() {
  # Cleanup unless VKDR_SKIP_TEARDOWN is set (for debugging)
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    helm_delete_if_exists "vkdr" "kong" || true
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
# Basic Installation Tests (DB-less mode - default)
# ============================================================================

# @doc: Install Kong in db-less mode (default)
# @example: vkdr kong install
@test "kong install: default dbless mode" {
  run vkdr kong install
  assert_success

  # Wait for helm release to be deployed
  run wait_for_helm_release "vkdr" "kong" 180
  assert_success
}

# @doc: Verify Kong proxy deployment is available
@test "kong install: proxy deployment becomes available" {
  # Wait for deployment to be available
  run wait_for_deployment "vkdr" "kong-kong" 180
  assert_success
}

# @doc: Verify Kong pods reach running state
@test "kong install: pods reach running state" {
  # Wait for Kong pods to be ready (may have controller and proxy pods)
  run wait_for_pods "vkdr" "app.kubernetes.io/instance=kong" 120
  assert_success
}

# @doc: Verify Kong proxy service is created
@test "kong install: proxy service is created" {
  run $VKDR_KUBECTL get service kong-kong-proxy -n vkdr
  assert_success

  # Verify proxy port 80
  run $VKDR_KUBECTL get service kong-kong-proxy -n vkdr -o jsonpath='{.spec.ports[?(@.name=="kong-proxy")].port}'
  assert_output "80"
}

# @doc: Verify Kong admin service is created (for manager access)
@test "kong install: admin service exists" {
  run $VKDR_KUBECTL get service kong-kong-admin -n vkdr
  assert_success
}

# @doc: Verify Kong proxy service has endpoints
@test "kong install: proxy service has endpoints" {
  run wait_for_endpoints "vkdr" "kong-kong-proxy" 90
  assert_success
}

# @doc: Verify Kong manager ingress is created
@test "kong install: manager ingress created with localhost host" {
  # Check ingress exists
  run $VKDR_KUBECTL get ingress kong-kong-manager -n vkdr
  assert_success

  # Verify ingress host for manager (manager.localhost by default)
  run $VKDR_KUBECTL get ingress kong-kong-manager -n vkdr -o jsonpath='{.spec.rules[0].host}'
  assert_output "manager.localhost"
}

# @doc: Verify Kong is responding via proxy
@test "kong install: proxy responds to requests" {
  # Wait a moment for Kong to fully initialize
  sleep 5

  # Test via port-forward to proxy service
  $VKDR_KUBECTL port-forward svc/kong-kong-proxy -n vkdr 18000:80 &
  local pf_pid=$!
  sleep 3

  # Kong returns 404 for unknown routes, which is expected
  run curl -s -o /dev/null -w '%{http_code}' http://localhost:18000/

  # Cleanup port-forward
  kill $pf_pid 2>/dev/null || true

  # 404 is expected (no routes configured), 200 would mean it hit something
  [[ "$output" == "404" ]] || [[ "$output" == "200" ]]
}

# ============================================================================
# Custom Domain Tests (DB-less mode)
# ============================================================================

# @doc: Install Kong with custom domain
# @example: vkdr kong install --domain example.com
@test "kong install: custom domain configuration" {
  # Clean previous install
  helm_delete_if_exists "vkdr" "kong" || true
  sleep 5

  run vkdr kong install --domain example.com
  assert_success

  # Wait for deployment
  run wait_for_deployment "vkdr" "kong-kong" 180
  assert_success

  # Verify manager ingress has custom domain
  run $VKDR_KUBECTL get ingress kong-kong-manager -n vkdr -o jsonpath='{.spec.rules[0].host}'
  assert_output "manager.example.com"
}

# ============================================================================
# TLS/Secure Mode Tests (DB-less mode)
# ============================================================================

# @doc: Install Kong with TLS enabled
# @example: vkdr kong install --domain example.com --secure
@test "kong install: TLS configuration" {
  # Clean previous install
  helm_delete_if_exists "vkdr" "kong" || true
  sleep 5

  run vkdr kong install --domain example.com --secure
  assert_success

  # Wait for deployment
  run wait_for_deployment "vkdr" "kong-kong" 180
  assert_success

  # Verify TLS is configured on manager ingress
  run $VKDR_KUBECTL get ingress kong-kong-manager -n vkdr -o jsonpath='{.spec.tls[0].hosts[0]}'
  assert_output "manager.example.com"
}

# ============================================================================
# Kong IngressClass Tests
# ============================================================================

# @doc: Verify Kong IngressClass is created
@test "kong install: ingressclass kong is created" {
  run $VKDR_KUBECTL get ingressclass kong
  assert_success
}

# @doc: Verify Kong is registered as ingress controller
@test "kong install: kong is registered as ingress controller" {
  run $VKDR_KUBECTL get ingressclass kong -o jsonpath='{.spec.controller}'
  assert_output "ingress-controllers.konghq.com/kong"
}
