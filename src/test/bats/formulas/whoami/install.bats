#!/usr/bin/env bats
# install.bats - Tests for: vkdr whoami install

load '../../helpers/common'

setup_file() {
  load_vkdr
  configure_detik "vkdr"
  if ! require_vkdr_cluster; then
    skip "VKDR cluster (vkdr-local) not available"
  fi
  helm_delete_if_exists "vkdr" "whoami" || true
  sleep 2
}

teardown_file() {
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    helm_delete_if_exists "vkdr" "whoami" || true
  fi
}

@test "whoami install: command succeeds" {
  run vkdr whoami install
  assert_success
  run wait_for_helm_release "vkdr" "whoami" 120
  assert_success
}

@test "whoami install: resources are created" {
  run wait_for_deployment "vkdr" "whoami" 120
  assert_success

  # Verify all resources exist
  run $VKDR_KUBECTL get deployment,service,ingress whoami -n vkdr
  assert_success

  # Verify ingress host
  run $VKDR_KUBECTL get ingress whoami -n vkdr -o jsonpath='{.spec.rules[0].host}'
  assert_output "whoami.localhost"
}

@test "whoami install: custom domain and TLS" {
  helm_delete_if_exists "vkdr" "whoami" || true
  sleep 2

  run vkdr whoami install --domain example.com --secure
  assert_success
  run wait_for_rollout "vkdr" "whoami" 120
  assert_success

  # Verify ingress TLS configuration
  run $VKDR_KUBECTL get ingress whoami -n vkdr -o jsonpath='{.spec.tls[0].hosts[0]}'
  assert_output "whoami.example.com"
}

@test "whoami install: custom labels" {
  helm_delete_if_exists "vkdr" "whoami" || true
  sleep 2

  run vkdr whoami install --label team=platform --label env=test
  assert_success
  run wait_for_rollout "vkdr" "whoami" 120
  assert_success

  # Verify labels
  run $VKDR_KUBECTL get deployment whoami -n vkdr -o jsonpath='{.metadata.labels.team}'
  assert_output "platform"
}
