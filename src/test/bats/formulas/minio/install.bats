#!/usr/bin/env bats
# install.bats - Tests for: vkdr minio install
#
# Tests validate MinIO object storage installation.
#
# PREREQUISITES:
#   - VKDR tools installed (vkdr init)
#   - VKDR k3d cluster running (vkdr infra up)

load '../../helpers/common'

# ============================================================================
# Setup & Teardown
# ============================================================================

setup_file() {
  load_vkdr
  configure_detik "vkdr"

  if ! require_vkdr_cluster; then
    skip "VKDR cluster not available"
  fi

  helm_delete_if_exists "vkdr" "minio" || true
  sleep 3
}

teardown_file() {
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    helm_delete_if_exists "vkdr" "minio" || true
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

@test "minio install: installs minio storage" {
  run vkdr minio install --password minio123
  assert_success

  run wait_for_helm_release "vkdr" "minio" 180
  assert_success
}

@test "minio install: deployment is available" {
  run wait_for_deployment "vkdr" "minio" 180
  assert_success
}

@test "minio install: pods are running" {
  run wait_for_pods "vkdr" "app.kubernetes.io/name=minio" 120
  assert_success
}

@test "minio install: service exists" {
  run $VKDR_KUBECTL get service minio -n vkdr
  assert_success
}

@test "minio install: console ingress is created" {
  run $VKDR_KUBECTL get ingress minio -n vkdr
  assert_success

  run $VKDR_KUBECTL get ingress minio -n vkdr -o jsonpath='{.spec.rules[0].host}'
  assert_output "minio.localhost"
}

# ============================================================================
# Custom Domain Tests
# ============================================================================

@test "minio install: custom domain" {
  helm_delete_if_exists "vkdr" "minio" || true
  sleep 5

  run vkdr minio install --password minio123 --domain example.com
  assert_success

  run wait_for_deployment "vkdr" "minio" 180
  assert_success

  run $VKDR_KUBECTL get ingress minio -n vkdr -o jsonpath='{.spec.rules[0].host}'
  assert_output "minio.example.com"
}
