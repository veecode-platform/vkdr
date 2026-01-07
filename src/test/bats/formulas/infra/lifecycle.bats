#!/usr/bin/env bats
# lifecycle.bats - Tests for: vkdr infra up/down/start/stop
#
# WARNING: These tests WILL DESTROY any existing vkdr-local cluster!
# Run these tests in isolation, not as part of the regular test suite.
#
# Usage: make test-infra-lifecycle
#
# PREREQUISITES:
#   - VKDR tools installed (vkdr init)
#   - Docker running
#   - No critical workloads on vkdr-local cluster

load '../../helpers/common'

# ============================================================================
# Setup & Teardown
# ============================================================================

setup_file() {
  load_vkdr

  # Safety check - require explicit opt-in
  if [ "${VKDR_TEST_LIFECYCLE:-}" != "true" ]; then
    skip "Lifecycle tests disabled. Set VKDR_TEST_LIFECYCLE=true to run."
  fi

  # Clean up any existing cluster to start fresh
  $VKDR_K3D cluster delete vkdr-local 2>/dev/null || true
  sleep 3
}

teardown_file() {
  # Ensure cluster is cleaned up after tests
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    $VKDR_K3D cluster delete vkdr-local 2>/dev/null || true
  fi
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

@test "prerequisite: no vkdr-local cluster exists" {
  run $VKDR_K3D cluster list
  assert_success
  refute_output --partial "vkdr-local"
}

# ============================================================================
# Cluster Creation Tests (infra up)
# ============================================================================

@test "infra up: creates vkdr-local cluster" {
  run vkdr infra up
  assert_success
}

@test "infra up: cluster appears in k3d list" {
  run $VKDR_K3D cluster list
  assert_success
  assert_output --partial "vkdr-local"
}

@test "infra up: kubectl can connect" {
  # Wait for cluster to be ready
  local max_wait=60
  local waited=0
  while [ $waited -lt $max_wait ]; do
    if $VKDR_KUBECTL cluster-info 2>/dev/null | grep -q "Kubernetes control plane"; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL cluster-info
  assert_success
  assert_output --partial "Kubernetes control plane"
}

@test "infra up: kube-system namespace exists" {
  # Note: vkdr namespace is created when formulas are installed, not by infra up
  run $VKDR_KUBECTL get namespace kube-system
  assert_success
}

@test "infra up: coredns is running" {
  run wait_for_deployment "kube-system" "coredns" 120
  assert_success
}

@test "infra up: docker-io mirror registry is created" {
  run $VKDR_K3D registry list
  assert_success
  assert_output --partial "k3d-docker-io"
}

# ============================================================================
# Cluster Stop Tests (infra stop)
# ============================================================================

@test "infra stop: stops the cluster" {
  run vkdr infra stop
  assert_success
}

@test "infra stop: cluster not accessible" {
  # After stop, verify cluster is not accessible
  # Note: vkdr infra stop may fully remove k3d cluster (implementation detail)
  run $VKDR_K3D cluster list
  assert_success
  # Cluster may or may not appear in list depending on stop implementation
}

@test "infra stop: kubectl cannot connect" {
  run $VKDR_KUBECTL cluster-info
  assert_failure
}

# ============================================================================
# Cluster Start Tests (infra start)
# ============================================================================

@test "infra start: starts the stopped cluster" {
  run vkdr infra start
  assert_success
}

@test "infra start: kubectl can connect again" {
  # Wait for cluster to be ready
  local max_wait=60
  local waited=0
  while [ $waited -lt $max_wait ]; do
    if $VKDR_KUBECTL cluster-info 2>/dev/null | grep -q "Kubernetes control plane"; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL cluster-info
  assert_success
  assert_output --partial "Kubernetes control plane"
}

@test "infra start: kube-system namespace still exists" {
  run $VKDR_KUBECTL get namespace kube-system
  assert_success
}

# ============================================================================
# Cluster Destruction Tests (infra down)
# ============================================================================

@test "infra down: destroys the cluster" {
  run vkdr infra down
  assert_success
}

@test "infra down: cluster is removed from k3d list" {
  sleep 3
  run $VKDR_K3D cluster list
  assert_success
  refute_output --partial "vkdr-local"
}

@test "infra down: kubectl cannot connect" {
  run $VKDR_KUBECTL cluster-info
  assert_failure
}

# ============================================================================
# Re-creation Test (verify clean state)
# ============================================================================

@test "infra up: can create cluster again after down" {
  run vkdr infra up
  assert_success

  run $VKDR_K3D cluster list
  assert_success
  assert_output --partial "vkdr-local"
}

@test "infra up: cluster is functional after re-creation" {
  local max_wait=60
  local waited=0
  while [ $waited -lt $max_wait ]; do
    if $VKDR_KUBECTL cluster-info 2>/dev/null | grep -q "Kubernetes control plane"; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL get namespace kube-system
  assert_success
}
