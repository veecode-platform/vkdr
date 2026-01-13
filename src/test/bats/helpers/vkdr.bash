#!/usr/bin/env bash
# vkdr.bash - VKDR-specific test helpers
#
# Provides functions to interact with VKDR CLI and access tool paths.
# Tests assume a VKDR k3d cluster is running (via 'vkdr infra up').

# Project paths
export VKDR_PROJECT_ROOT="${VKDR_PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)}"

# VKDR tool paths (same as tools-paths.sh)
export VKDR_HOME="${VKDR_HOME:-$HOME/.vkdr}"
export VKDR_ARKADE="$VKDR_HOME/bin/arkade"
export VKDR_K3D="$VKDR_HOME/bin/k3d"
export VKDR_HELM="$VKDR_HOME/bin/helm"
export VKDR_KUBECTL="$VKDR_HOME/bin/kubectl"
export VKDR_YQ="$VKDR_HOME/bin/yq"
export VKDR_JQ="$VKDR_HOME/bin/jq"
export VKDR_GLOW="$VKDR_HOME/bin/glow"
export VKDR_VAULT="$VKDR_HOME/bin/vault"

# VKDR cluster name
export VKDR_CLUSTER_NAME="vkdr-local"

# ============================================================================
# VKDR Command Execution
# ============================================================================
#
# Test modes (set via VKDR_TEST_MODE env var):
#   - "dev"    : Maven exec + source formulas (DEFAULT - tests current code)
#   - "binary" : Native binary + extracted formulas (tests compiled release)
#
# In dev mode, VKDR_FORMULA_HOME is automatically set to source formulas.

export VKDR_TEST_MODE="${VKDR_TEST_MODE:-dev}"

# Run a vkdr command
# Usage: vkdr <args...>
vkdr() {
  local silent_mode=false
  if [[ " $* " =~ " --silent " ]]; then
    silent_mode=true
  fi

  if [ "$VKDR_TEST_MODE" = "binary" ]; then
    # Binary mode: use compiled native binary
    if [ ! -x "$VKDR_PROJECT_ROOT/target/vkdr" ]; then
      echo "ERROR: Native binary not found at $VKDR_PROJECT_ROOT/target/vkdr" >&2
      echo "Run: ./mvnw native:compile -Pnative" >&2
      return 1
    fi
    "$VKDR_PROJECT_ROOT/target/vkdr" "$@"
  else
    # Dev mode (default): Maven exec + source formulas
    export VKDR_FORMULA_HOME="$VKDR_PROJECT_ROOT/src/main/resources/formulas"
    if [ "$silent_mode" = "true" ]; then
      # Filter warnings in silent mode (matches vkdr.sh behavior)
      (cd "$VKDR_PROJECT_ROOT" && mvn -q exec:java \
        -Dexec.mainClass=codes.vee.vkdr.VkdrApplication \
        -Dexec.args="$*" 2>&1 | grep -v "WARNING:")
    else
      (cd "$VKDR_PROJECT_ROOT" && mvn -q exec:java \
        -Dexec.mainClass=codes.vee.vkdr.VkdrApplication \
        -Dexec.args="$*")
    fi
  fi
}

# Run vkdr in silent mode
vkdr_silent() {
  VKDR_SILENT=true vkdr "$@"
}

# Check if VKDR tools are installed
check_vkdr_tools() {
  local missing=()

  [ -x "$VKDR_KUBECTL" ] || missing+=("kubectl")
  [ -x "$VKDR_HELM" ] || missing+=("helm")
  [ -x "$VKDR_YQ" ] || missing+=("yq")
  [ -x "$VKDR_JQ" ] || missing+=("jq")
  [ -x "$VKDR_K3D" ] || missing+=("k3d")

  if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing VKDR tools: ${missing[*]}" >&2
    echo "Run 'vkdr init' to install required tools." >&2
    return 1
  fi
  return 0
}

# ============================================================================
# VKDR Cluster Management
# ============================================================================

# Check if VKDR k3d cluster exists
vkdr_cluster_exists() {
  $VKDR_K3D cluster list 2>/dev/null | grep -q "$VKDR_CLUSTER_NAME"
}

# Check if VKDR k3d cluster is running
vkdr_cluster_running() {
  local status
  status=$($VKDR_K3D cluster list -o json 2>/dev/null | \
    $VKDR_JQ -r ".[] | select(.name == \"$VKDR_CLUSTER_NAME\") | .serversRunning") || return 1
  [ "$status" -gt 0 ] 2>/dev/null
}

# Get current k8s context
get_context() {
  $VKDR_KUBECTL config current-context 2>/dev/null
}

# Check if current context is the VKDR cluster
is_vkdr_context() {
  local context
  context="$(get_context)"
  [ "$context" = "k3d-$VKDR_CLUSTER_NAME" ]
}

# Check if kubectl can connect to cluster
check_cluster_connection() {
  $VKDR_KUBECTL cluster-info &>/dev/null
}

# Comprehensive VKDR cluster check
# Returns 0 if cluster exists, is running, and kubectl can connect
check_vkdr_cluster() {
  if ! vkdr_cluster_exists; then
    echo "VKDR cluster '$VKDR_CLUSTER_NAME' does not exist." >&2
    echo "Run 'vkdr infra up' to create it." >&2
    return 1
  fi

  if ! vkdr_cluster_running; then
    echo "VKDR cluster '$VKDR_CLUSTER_NAME' exists but is not running." >&2
    echo "Run 'vkdr infra start' to start it." >&2
    return 1
  fi

  if ! is_vkdr_context; then
    echo "kubectl context is not set to VKDR cluster." >&2
    echo "Current context: $(get_context)" >&2
    echo "Expected: k3d-$VKDR_CLUSTER_NAME" >&2
    echo "Run: kubectl config use-context k3d-$VKDR_CLUSTER_NAME" >&2
    return 1
  fi

  if ! check_cluster_connection; then
    echo "Cannot connect to VKDR cluster." >&2
    return 1
  fi

  return 0
}

# ============================================================================
# Test Skip Helpers
# ============================================================================

# Skip entire test file if VKDR cluster is not ready
# Use in setup_file() for formula tests
require_vkdr_cluster() {
  if ! check_vkdr_cluster; then
    echo "# SKIP: VKDR cluster not available" >&3 2>/dev/null || true
    return 1
  fi
  return 0
}

# Skip individual test if no cluster
skip_if_no_cluster() {
  if ! check_cluster_connection; then
    skip "No Kubernetes cluster available"
  fi
}

# Skip test if not on VKDR cluster
skip_if_not_vkdr_cluster() {
  if ! is_vkdr_context; then
    skip "Not running on VKDR cluster (k3d-$VKDR_CLUSTER_NAME)"
  fi
}

# Get helm release status
# Usage: helm_release_status <namespace> <release>
helm_release_status() {
  local namespace="$1"
  local release="$2"
  $VKDR_HELM status "$release" -n "$namespace" -o json 2>/dev/null | $VKDR_JQ -r '.info.status'
}

# Check if helm release exists
# Usage: helm_release_exists <namespace> <release>
helm_release_exists() {
  local namespace="$1"
  local release="$2"
  $VKDR_HELM status "$release" -n "$namespace" &>/dev/null
}

# Delete helm release if it exists
# Usage: helm_delete_if_exists <namespace> <release>
helm_delete_if_exists() {
  local namespace="$1"
  local release="$2"
  if helm_release_exists "$namespace" "$release"; then
    $VKDR_HELM delete "$release" -n "$namespace" --wait
  fi
}

# Create namespace if it doesn't exist
# Usage: ensure_namespace <namespace>
ensure_namespace() {
  local namespace="$1"
  $VKDR_KUBECTL get namespace "$namespace" &>/dev/null || \
    $VKDR_KUBECTL create namespace "$namespace"
}

# Delete namespace and wait
# Usage: delete_namespace <namespace>
delete_namespace() {
  local namespace="$1"
  $VKDR_KUBECTL delete namespace "$namespace" --ignore-not-found=true --wait=true
}
