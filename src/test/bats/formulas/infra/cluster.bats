#!/usr/bin/env bats
# cluster.bats - Tests for: vkdr infra (start/stop/expose/createtoken/getca)
#
# NOTE: These tests verify cluster operations without destroying the test cluster.
# Full start/stop cycle tests should be run manually or in isolation.
#
# PREREQUISITES:
#   - VKDR tools installed (vkdr init)
#   - Docker running

load '../../helpers/common'

# ============================================================================
# Setup & Teardown
# ============================================================================

setup_file() {
  load_vkdr
  configure_detik "vkdr"
}

# ============================================================================
# Prerequisite Tests
# ============================================================================

@test "prerequisite: vkdr tools are installed" {
  run check_vkdr_tools
  assert_success
}

@test "prerequisite: docker is running" {
  run docker info
  assert_success
}

# ============================================================================
# Cluster Status Tests (non-destructive)
# ============================================================================

@test "infra: cluster vkdr-local exists" {
  run $VKDR_K3D cluster list
  assert_success
  if ! echo "$output" | grep -q "vkdr-local"; then
    skip "VKDR cluster not running - this is expected when no cluster exists"
  fi
  assert_output --partial "vkdr-local"
}

@test "infra: kubectl can connect to cluster" {
  if ! $VKDR_K3D cluster list 2>/dev/null | grep -q "vkdr-local"; then
    skip "VKDR cluster not running"
  fi

  run $VKDR_KUBECTL cluster-info
  assert_success
  assert_output --partial "Kubernetes control plane"
}

@test "infra: vkdr namespace exists" {
  if ! $VKDR_K3D cluster list 2>/dev/null | grep -q "vkdr-local"; then
    skip "VKDR cluster not running"
  fi

  run $VKDR_KUBECTL get namespace vkdr
  assert_success
}

@test "infra: coredns is running" {
  if ! $VKDR_K3D cluster list 2>/dev/null | grep -q "vkdr-local"; then
    skip "VKDR cluster not running"
  fi

  run $VKDR_KUBECTL get deployment coredns -n kube-system
  assert_success
}

# ============================================================================
# Token Creation Tests
# ============================================================================

@test "infra createToken: creates api-client service account" {
  if ! $VKDR_K3D cluster list 2>/dev/null | grep -q "vkdr-local"; then
    skip "VKDR cluster not running"
  fi

  run vkdr infra createToken --duration 1h
  assert_success

  # Verify token is returned (JWT format)
  [[ "$output" =~ ^eyJ ]]
}

@test "infra createToken: json output format" {
  if ! $VKDR_K3D cluster list 2>/dev/null | grep -q "vkdr-local"; then
    skip "VKDR cluster not running"
  fi

  run vkdr infra createToken --duration 1h --json
  assert_success

  # Verify JSON format
  echo "$output" | $VKDR_JQ -e '.token' > /dev/null
}

@test "infra createToken: service account exists after creation" {
  if ! $VKDR_K3D cluster list 2>/dev/null | grep -q "vkdr-local"; then
    skip "VKDR cluster not running"
  fi

  run $VKDR_KUBECTL get serviceaccount api-client
  assert_success
}

@test "infra createToken: cluster role binding exists" {
  if ! $VKDR_K3D cluster list 2>/dev/null | grep -q "vkdr-local"; then
    skip "VKDR cluster not running"
  fi

  run $VKDR_KUBECTL get clusterrolebinding api-client-cluster-admin
  assert_success
}

# ============================================================================
# CA Retrieval Tests
# ============================================================================

@test "infra getca: retrieves CA data" {
  if ! $VKDR_K3D cluster list 2>/dev/null | grep -q "vkdr-local"; then
    skip "VKDR cluster not running"
  fi

  run vkdr infra getca
  assert_success

  # CA data should be base64 encoded
  [[ -n "$output" ]]
}

@test "infra getca: json output format" {
  if ! $VKDR_K3D cluster list 2>/dev/null | grep -q "vkdr-local"; then
    skip "VKDR cluster not running"
  fi

  run vkdr infra getca --json
  assert_success

  # Verify JSON format
  echo "$output" | $VKDR_JQ -e '.caData' > /dev/null
}

# ============================================================================
# Mirror Registry Tests (non-destructive)
# ============================================================================

@test "infra: docker-io mirror registry exists" {
  run $VKDR_K3D registry list
  assert_success
  assert_output --partial "k3d-docker-io"
}
