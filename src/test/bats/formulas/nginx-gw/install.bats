#!/usr/bin/env bats
# install.bats - Tests for: vkdr nginx-gw install

load '../../helpers/common'

setup_file() {
  load_vkdr
  configure_detik "nginx-gateway"
  require_vkdr_cluster || skip "VKDR cluster not available"
  helm_delete_if_exists "nginx-gateway" "nginx-gateway" || true
  sleep 2
}

teardown_file() {
  [ "${VKDR_SKIP_TEARDOWN:-}" = "true" ] || helm_delete_if_exists "nginx-gateway" "nginx-gateway" || true
}

@test "nginx-gw install: command succeeds" {
  run vkdr nginx-gw install
  assert_success
}

@test "nginx-gw install: controller is ready" {
  run wait_for_deployment "nginx-gateway" "nginx-gateway-nginx-gateway-fabric" 90
  assert_success
}

@test "nginx-gw install: resources are created" {
  # Check service, gatewayclass, CRDs, and gateway in one test
  run $VKDR_KUBECTL get service nginx-gateway-nginx-gateway-fabric -n nginx-gateway
  assert_success

  run $VKDR_KUBECTL get gatewayclass nginx
  assert_success

  run $VKDR_KUBECTL get crd gateways.gateway.networking.k8s.io
  assert_success

  run $VKDR_KUBECTL get gateway nginx -n nginx-gateway
  assert_success
}
