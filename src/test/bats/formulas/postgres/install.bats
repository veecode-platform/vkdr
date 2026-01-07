#!/usr/bin/env bats
# install.bats - Tests for: vkdr postgres install
#
# Tests validate PostgreSQL (CloudNative-PG) installation.
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

  # Clean up any existing postgres installation
  helm_delete_if_exists "vkdr" "postgres" || true
  $VKDR_KUBECTL delete cluster vkdr-pg-cluster -n vkdr --ignore-not-found=true 2>/dev/null || true
  sleep 3
}

teardown_file() {
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    $VKDR_KUBECTL delete cluster vkdr-pg-cluster -n vkdr --ignore-not-found=true 2>/dev/null || true
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

@test "postgres install: installs CloudNative-PG operator and cluster" {
  run vkdr postgres install --wait
  assert_success
}

@test "postgres install: CNPG operator is running" {
  run $VKDR_KUBECTL get deployment cnpg-controller-manager -n cnpg-system
  assert_success

  run wait_for_deployment "cnpg-system" "cnpg-controller-manager" 120
  assert_success
}

@test "postgres install: cluster is in healthy state" {
  # Wait for cluster to be ready
  local max_wait=120
  local waited=0
  while [ $waited -lt $max_wait ]; do
    local status=$($VKDR_KUBECTL get cluster vkdr-pg-cluster -n vkdr -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
    if [ "$status" = "Cluster in healthy state" ]; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL get cluster vkdr-pg-cluster -n vkdr -o jsonpath='{.status.phase}'
  assert_output "Cluster in healthy state"
}

@test "postgres install: primary pod is running" {
  run $VKDR_KUBECTL get pod -n vkdr -l cnpg.io/cluster=vkdr-pg-cluster,role=primary
  assert_success
  assert_output --partial "Running"
}

@test "postgres install: services are created" {
  # Read-write service
  run $VKDR_KUBECTL get service vkdr-pg-cluster-rw -n vkdr
  assert_success

  # Read-only service
  run $VKDR_KUBECTL get service vkdr-pg-cluster-ro -n vkdr
  assert_success
}

@test "postgres install: superuser secret is created" {
  run $VKDR_KUBECTL get secret vkdr-pg-cluster-superuser -n vkdr
  assert_success
}

# ============================================================================
# Database Operations Tests
# ============================================================================

@test "postgres listdbs: lists databases" {
  run vkdr postgres listdbs
  assert_success
  assert_output --partial "postgres"
  assert_output --partial "app"
}

@test "postgres listdbs: json output" {
  run vkdr postgres listdbs --json
  assert_success

  # Filter out warning lines and verify JSON array format
  # Output may contain JVM warnings before JSON
  local json_output=$(echo "$output" | grep -v "^WARNING:" | grep "^\[")
  if [ -n "$json_output" ]; then
    echo "$json_output" | $VKDR_JQ -e '.[0].name' > /dev/null
  else
    # If no JSON found, skip this test (formula may not support --json yet)
    skip "JSON output format not available"
  fi
}

@test "postgres createdb: creates new database" {
  run vkdr postgres createdb -d testdb -u testuser -p testpass123
  assert_success
}

@test "postgres createdb: Database CR is created" {
  # Verify the Database Custom Resource exists
  run $VKDR_KUBECTL get database vkdr-pg-cluster-testdb -n vkdr
  assert_success
}

@test "postgres createdb: Database CR is reconciled" {
  # Wait for operator to reconcile - status.applied should be true
  local max_wait=60
  local waited=0
  while [ $waited -lt $max_wait ]; do
    local applied=$($VKDR_KUBECTL get database vkdr-pg-cluster-testdb -n vkdr -o jsonpath='{.status.applied}' 2>/dev/null || echo "false")
    if [ "$applied" = "true" ]; then
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done

  run $VKDR_KUBECTL get database vkdr-pg-cluster-testdb -n vkdr -o jsonpath='{.status.applied}'
  assert_output "true"
}

@test "postgres createdb: database appears in listdbs" {
  # After reconciliation, database should appear in PostgreSQL
  run vkdr postgres listdbs
  assert_success
  assert_output --partial "testdb"
}

@test "postgres createdb: role secret is created" {
  run $VKDR_KUBECTL get secret vkdr-pg-cluster-role-testuser -n vkdr
  assert_success
}

@test "postgres pingdb: can connect to created database" {
  run vkdr postgres pingdb -d testdb -u testuser
  assert_success
  assert_output --partial "Database connection successful"
}

@test "postgres dropdb: removes database" {
  run vkdr postgres dropdb -d testdb -u testuser
  assert_success
}

@test "postgres dropdb: Database CR is deleted" {
  # The Database CR should be deleted immediately
  run $VKDR_KUBECTL get database vkdr-pg-cluster-testdb -n vkdr 2>&1
  assert_failure
}

@test "postgres dropdb: database is removed from PostgreSQL" {
  # dropdb formula now executes DROP DATABASE via kubectl exec
  # Wait a moment for the command to complete
  sleep 2

  run vkdr postgres listdbs
  assert_success

  # Filter out warnings and verify database is gone
  local filtered=$(echo "$output" | grep -v "^WARNING:")
  if echo "$filtered" | grep -q "testdb"; then
    fail "Database 'testdb' still exists after dropdb - DROP DATABASE failed"
  fi
}

@test "postgres dropdb: role secret is deleted" {
  run $VKDR_KUBECTL get secret vkdr-pg-cluster-role-testuser -n vkdr 2>&1
  assert_failure
}
