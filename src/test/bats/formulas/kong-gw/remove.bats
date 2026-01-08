#!/usr/bin/env bats
# remove.bats - Tests for: vkdr kong-gw remove

load '../../helpers/common'

setup_file() {
  load_vkdr
  configure_detik "kong-system"
  require_vkdr_cluster || skip "VKDR cluster not available"

  # Ensure kong-gw is installed before testing removal
  if ! $VKDR_HELM list -n kong-system | grep -q "kong-operator"; then
    vkdr kong-gw install
    wait_for_deployment "kong-system" "kong-operator-kong-operator-controller-manager" 120
  fi
}

teardown_file() {
  helm_delete_if_exists "kong-system" "kong-operator" || true
}

@test "kong-gw remove: command succeeds" {
  run vkdr kong-gw remove --delete-operator
  assert_success
}

@test "kong-gw remove: resources are cleaned up" {
  sleep 3

  # Helm release deleted
  run $VKDR_HELM list -n kong-system -q
  refute_output --partial "kong-operator"

  # GatewayClass deleted
  run $VKDR_KUBECTL get gatewayclass kong 2>&1
  assert_failure
}
