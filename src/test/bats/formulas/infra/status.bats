#!/usr/bin/env bats
# status.bats - Tests for: vkdr infra status
#
# NOTE: These tests manage their own cluster lifecycle using vkdr infra up/down.
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

  # Ensure cluster is running for tests
  if ! $VKDR_K3D cluster list 2>/dev/null | grep -q "vkdr-local"; then
    vkdr infra up
    # Wait for API server to be ready
    local max_wait=60
    local waited=0
    while [ $waited -lt $max_wait ]; do
      if $VKDR_KUBECTL cluster-info 2>/dev/null | grep -q "Kubernetes control plane"; then
        break
      fi
      sleep 5
      waited=$((waited + 5))
    done
  fi
}

teardown_file() {
  # Clean up cluster after tests
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    vkdr infra down 2>/dev/null || true
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

# ============================================================================
# Status Command Tests
# ============================================================================

@test "infra status: returns success when cluster is running" {
  run vkdr infra status
  assert_success
}

@test "infra status: shows cluster name" {
  run vkdr infra status
  assert_success
  assert_output --partial "vkdr-local"
}

@test "infra status: shows READY status when healthy" {
  run vkdr infra status
  assert_success
  assert_output --partial "READY"
}

@test "infra status: shows server count" {
  run vkdr infra status
  assert_success
  assert_output --partial "running"
}

# ============================================================================
# JSON Output Tests (use --silent for clean output)
# ============================================================================

@test "infra status --json: returns valid JSON" {
  run vkdr infra status --json --silent
  assert_success
  echo "$output" | $VKDR_JQ -e '.' > /dev/null
}

@test "infra status --json: contains cluster field" {
  run vkdr infra status --json --silent
  assert_success
  local cluster
  cluster=$(echo "$output" | $VKDR_JQ -r '.cluster')
  [ "$cluster" = "vkdr-local" ]
}

@test "infra status --json: contains status field" {
  run vkdr infra status --json --silent
  assert_success
  local status
  status=$(echo "$output" | $VKDR_JQ -r '.status')
  [ "$status" = "READY" ]
}

@test "infra status --json: contains server counts" {
  run vkdr infra status --json --silent
  assert_success

  local servers_count servers_running
  servers_count=$(echo "$output" | $VKDR_JQ -r '.servers_count')
  servers_running=$(echo "$output" | $VKDR_JQ -r '.servers_running')

  [ "$servers_count" -gt 0 ]
  [ "$servers_running" -gt 0 ]
}

@test "infra status --json: contains api_server_reachable field" {
  run vkdr infra status --json --silent
  assert_success

  local api_reachable
  api_reachable=$(echo "$output" | $VKDR_JQ -r '.api_server_reachable')
  [ "$api_reachable" = "true" ]
}

# ============================================================================
# Stopped Cluster Tests (must run last - stops the cluster)
# ============================================================================

@test "infra status --json: succeeds when cluster is stopped" {
  # Stop the cluster first
  vkdr infra down

  run vkdr infra status --json --silent
  assert_success
  echo "$output" | $VKDR_JQ -e '.' > /dev/null
}

@test "infra status --json: returns NOT_READY when cluster is stopped" {
  run vkdr infra status --json --silent
  assert_success

  local status
  status=$(echo "$output" | $VKDR_JQ -r '.status')
  [ "$status" = "NOT_READY" ]
}

@test "infra status --json: returns exists=false when cluster is stopped" {
  run vkdr infra status --json --silent
  assert_success

  local exists
  exists=$(echo "$output" | $VKDR_JQ -r '.exists')
  [ "$exists" = "false" ]
}
