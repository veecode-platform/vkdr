#!/usr/bin/env bats
# install.bats - Tests for: vkdr kong-gw install

load '../../helpers/common'

setup_file() {
  load_vkdr
  configure_detik "kong-system"
  require_vkdr_cluster || skip "VKDR cluster not available"
  helm_delete_if_exists "kong-system" "kong-operator" || true
  sleep 2
}

teardown_file() {
  [ "${VKDR_SKIP_TEARDOWN:-}" = "true" ] || helm_delete_if_exists "kong-system" "kong-operator" || true
}

@test "kong-gw install: command succeeds" {
  run vkdr kong-gw install
  assert_success
}

@test "kong-gw install: operator is ready" {
  run wait_for_deployment "kong-system" "kong-operator-kong-operator-controller-manager" 120
  assert_success
}

@test "kong-gw install: resources are created" {
  # Check gatewayclass
  run $VKDR_KUBECTL get gatewayclass kong
  assert_success

  # Check CRDs
  run $VKDR_KUBECTL get crd gateways.gateway.networking.k8s.io
  assert_success

  # Check gateway
  run $VKDR_KUBECTL get gateway kong -n kong-system
  assert_success
}

@test "kong-gw install: gateway is programmed" {
  # Wait for Gateway to be programmed
  local max_wait=120
  local waited=0
  while [ $waited -lt $max_wait ]; do
    local programmed=$($VKDR_KUBECTL get gateway kong -n kong-system -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}' 2>/dev/null || echo "")
    [ "$programmed" = "True" ] && break
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL get gateway kong -n kong-system -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}'
  assert_output "True"
}
