#!/usr/bin/env bats
# remove.bats - Tests for: vkdr whoami remove

load '../../helpers/common'

setup_file() {
  load_vkdr
  configure_detik "vkdr"
  if ! require_vkdr_cluster; then
    skip "VKDR cluster (vkdr-local) not available"
  fi
  # Ensure whoami is installed before testing removal
  if ! helm_release_exists "vkdr" "whoami"; then
    vkdr whoami install
    wait_for_rollout "vkdr" "whoami" 120
  fi
}

teardown_file() {
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    helm_delete_if_exists "vkdr" "whoami" || true
  fi
}

@test "whoami remove: command succeeds" {
  run helm_release_exists "vkdr" "whoami"
  assert_success

  run vkdr whoami remove
  assert_success
}

@test "whoami remove: resources are cleaned up" {
  sleep 3

  # All resources should be gone
  run $VKDR_KUBECTL get deployment whoami -n vkdr 2>&1
  assert_failure

  run $VKDR_KUBECTL get service whoami -n vkdr 2>&1
  assert_failure

  run $VKDR_KUBECTL get ingress whoami -n vkdr 2>&1
  assert_failure

  run helm_release_exists "vkdr" "whoami"
  assert_failure
}
