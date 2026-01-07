#!/usr/bin/env bats
# install.bats - Tests for: vkdr openldap install
#
# Tests validate OpenLDAP directory server installation.
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

  helm_delete_if_exists "vkdr" "openldap" || true
  sleep 3
}

teardown_file() {
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    helm_delete_if_exists "vkdr" "openldap" || true
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

@test "openldap install: installs openldap server" {
  run vkdr openldap install --admin_user admin --admin_password admin123
  assert_success

  run wait_for_helm_release "vkdr" "openldap" 180
  assert_success
}

@test "openldap install: statefulset is available" {
  local max_wait=180
  local waited=0
  while [ $waited -lt $max_wait ]; do
    if $VKDR_KUBECTL get statefulset openldap -n vkdr 2>/dev/null | grep -q "1/1"; then
      break
    fi
    sleep 10
    waited=$((waited + 10))
  done

  run $VKDR_KUBECTL get statefulset openldap -n vkdr
  assert_success
}

@test "openldap install: pods are running" {
  run wait_for_pods "vkdr" "app.kubernetes.io/name=openldap-stack-ha" 180
  assert_success
}

@test "openldap install: service exists" {
  run $VKDR_KUBECTL get service openldap -n vkdr
  assert_success
}

@test "openldap install: ldap port is exposed" {
  run $VKDR_KUBECTL get service openldap -n vkdr -o jsonpath='{.spec.ports[?(@.name=="ldap-port")].port}'
  assert_success
  assert_output "389"
}

# ============================================================================
# Configuration Tests
# ============================================================================

@test "openldap install: with phpldapadmin" {
  helm_delete_if_exists "vkdr" "openldap" || true
  sleep 5

  run vkdr openldap install --admin_user admin --admin_password admin123 --ldap-admin
  assert_success

  run wait_for_helm_release "vkdr" "openldap" 180
  assert_success

  # Check if phpldapadmin deployment exists
  run $VKDR_KUBECTL get deployment openldap-phpldapadmin -n vkdr
  assert_success
}
