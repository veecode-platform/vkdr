#!/usr/bin/env bash
# common.bash - Common test setup for VKDR BATS tests
#
# This file loads all required libraries and sets up the test environment.
# Source this from your .bats files using: load '../../helpers/common'

# Determine paths relative to this file
_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export VKDR_PROJECT_ROOT="$(cd "$_COMMON_DIR/../../../.." && pwd)"
export BATS_LIBS_DIR="$VKDR_PROJECT_ROOT/.bats-libs"

# Load BATS helper libraries
load "$BATS_LIBS_DIR/bats-support/load"
load "$BATS_LIBS_DIR/bats-assert/load"

# Load bats-detik
export DETIK_CLIENT_NAME=""  # Will be set after loading vkdr.bash
source "$BATS_LIBS_DIR/bats-detik/lib/detik.bash"

# Load VKDR-specific helpers
source "$_COMMON_DIR/vkdr.bash"
source "$_COMMON_DIR/k8s-wait.bash"

# Default test timeout (can be overridden per-test)
export BATS_TEST_TIMEOUT="${BATS_TEST_TIMEOUT:-300}"

# Initialize VKDR environment
load_vkdr() {
  # Set VKDR_FORMULA_HOME for development testing
  export VKDR_FORMULA_HOME="${VKDR_FORMULA_HOME:-$VKDR_PROJECT_ROOT/src/main/resources/formulas}"
}

# Configure bats-detik to use VKDR's kubectl
configure_detik() {
  export DETIK_CLIENT_NAME="$VKDR_KUBECTL"
  export DETIK_CLIENT_NAMESPACE="${1:-vkdr}"
}
