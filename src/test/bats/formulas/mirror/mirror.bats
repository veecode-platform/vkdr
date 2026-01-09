#!/usr/bin/env bats
# mirror.bats - Tests for: vkdr mirror add/list/remove
#
# Tests validate container registry mirror configuration.
# NOTE: Mirror configuration doesn't require a running cluster,
# but the mirrors are used when creating the cluster.
#
# PREREQUISITES:
#   - VKDR tools installed (vkdr init)

load '../../helpers/common'

MIRROR_CONFIG="${HOME}/.vkdr/configs/mirror-registry.yaml"
TEST_HOST="test.mirror.example.com"

# ============================================================================
# Setup & Teardown
# ============================================================================

setup_file() {
  load_vkdr

  # Backup existing mirror config if present
  if [ -f "$MIRROR_CONFIG" ]; then
    cp "$MIRROR_CONFIG" "${MIRROR_CONFIG}.bak"
  fi
}

teardown_file() {
  # Remove test mirror if added
  if [ -f "$MIRROR_CONFIG" ]; then
    # Try to remove test mirror
    export HOST="\"${TEST_HOST}\""
    $VKDR_YQ eval -i 'del(.mirrors[env(HOST)])' "$MIRROR_CONFIG" 2>/dev/null || true
    unset HOST

    # Check if mirrors section is empty and clean up
    if [ "$($VKDR_YQ eval '.mirrors | length' "$MIRROR_CONFIG" 2>/dev/null)" -eq 0 ]; then
      $VKDR_YQ eval -i 'del(.mirrors)' "$MIRROR_CONFIG" 2>/dev/null || true
    fi
  fi

  # Restore original config if it existed
  if [ -f "${MIRROR_CONFIG}.bak" ]; then
    mv "${MIRROR_CONFIG}.bak" "$MIRROR_CONFIG"
  fi
}

setup() {
  load_vkdr
}

# ============================================================================
# Prerequisite Tests
# ============================================================================

@test "prerequisite: vkdr tools are installed" {
  run check_vkdr_tools
  assert_success
}

# ============================================================================
# Mirror Add Tests
# ============================================================================

@test "mirror add: command succeeds" {
  run vkdr mirror add --host "$TEST_HOST"
  assert_success
}

@test "mirror add: mirror config file is created" {
  [ -f "$MIRROR_CONFIG" ]
}

@test "mirror add: mirror is in config" {
  run $VKDR_YQ eval ".mirrors.\"$TEST_HOST\"" "$MIRROR_CONFIG"
  assert_success
  assert_output --partial "endpoint"
}

@test "mirror add: duplicate mirror is ignored" {
  run vkdr mirror add --host "$TEST_HOST"
  assert_success
  assert_output --partial "already exists"
}

# ============================================================================
# Mirror List Tests
# ============================================================================

@test "mirror list: command succeeds" {
  run vkdr mirror list
  assert_success
}

@test "mirror list: shows added mirror" {
  run vkdr mirror list
  assert_success
  assert_output --partial "$TEST_HOST"
}

# ============================================================================
# Mirror Remove Tests
# ============================================================================

@test "mirror remove: command succeeds" {
  run vkdr mirror remove --host "$TEST_HOST"
  assert_success
}

@test "mirror remove: mirror is removed from config" {
  run $VKDR_YQ eval ".mirrors.\"$TEST_HOST\"" "$MIRROR_CONFIG" 2>/dev/null
  # Should return null or empty since mirror was removed
  refute_output --partial "endpoint"
}

@test "mirror remove: non-existent mirror fails gracefully" {
  run vkdr mirror remove --host "non.existent.mirror"
  # Command should either succeed silently or fail with error message
  # Either is acceptable behavior
  [ "$status" -eq 0 ] || assert_output --partial "does not exist"
}

# ============================================================================
# Mirror Add Again (for cleanup validation)
# ============================================================================

@test "mirror add: can re-add after removal" {
  run vkdr mirror add --host "$TEST_HOST"
  assert_success
  refute_output --partial "already exists"
}
