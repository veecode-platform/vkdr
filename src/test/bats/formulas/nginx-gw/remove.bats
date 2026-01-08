#!/usr/bin/env bats
# remove.bats - Tests for: vkdr nginx-gw remove

load '../../helpers/common'

setup_file() {
  load_vkdr
  configure_detik "nginx-gateway"
  require_vkdr_cluster || skip "VKDR cluster not available"

  # Ensure nginx-gateway is installed before testing removal
  if ! $VKDR_HELM list -n nginx-gateway | grep -q "nginx-gateway"; then
    vkdr nginx-gw install
    wait_for_deployment "nginx-gateway" "nginx-gateway-nginx-gateway-fabric" 90
  fi
}

teardown_file() {
  helm_delete_if_exists "nginx-gateway" "nginx-gateway" || true
}

@test "nginx-gw remove: command succeeds" {
  run vkdr nginx-gw remove --delete-fabric
  assert_success
}

@test "nginx-gw remove: resources are cleaned up" {
  sleep 3

  # Helm release deleted
  run $VKDR_HELM list -n nginx-gateway -q
  refute_output --partial "nginx-gateway"

  # Deployment deleted
  run $VKDR_KUBECTL get deployment nginx-gateway-nginx-gateway-fabric -n nginx-gateway 2>&1
  assert_failure
}
