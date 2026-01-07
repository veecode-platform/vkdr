#!/usr/bin/env bash
# k8s-wait.bash - Kubernetes wait/retry helpers for async operations
#
# Kubernetes commands return before resources are ready. These helpers
# provide robust waiting and retry mechanisms for tests.

# ============================================================================
# Generic Wait Helpers
# ============================================================================

# Wait for a condition with retries
# Usage: wait_for_condition <max_attempts> <sleep_seconds> <command...>
# Example: wait_for_condition 10 3 kubectl get pod nginx
wait_for_condition() {
  local max_attempts="$1"
  local sleep_sec="$2"
  shift 2
  local cmd="$*"

  local attempt=1
  while [ "$attempt" -le "$max_attempts" ]; do
    if eval "$cmd" &>/dev/null; then
      return 0
    fi
    # Output to fd 3 for BATS verbose mode
    echo "# Attempt $attempt/$max_attempts failed, waiting ${sleep_sec}s..." >&3 2>/dev/null || true
    sleep "$sleep_sec"
    ((attempt++))
  done
  echo "# Condition not met after $max_attempts attempts" >&3 2>/dev/null || true
  return 1
}

# Wait for a command output to match expected value
# Usage: wait_for_output <max_attempts> <sleep_seconds> <expected> <command...>
wait_for_output() {
  local max_attempts="$1"
  local sleep_sec="$2"
  local expected="$3"
  shift 3
  local cmd="$*"

  local attempt=1
  local output
  while [ "$attempt" -le "$max_attempts" ]; do
    output=$(eval "$cmd" 2>/dev/null) || true
    if [ "$output" = "$expected" ]; then
      return 0
    fi
    echo "# Attempt $attempt/$max_attempts: got '$output', expected '$expected'" >&3 2>/dev/null || true
    sleep "$sleep_sec"
    ((attempt++))
  done
  return 1
}

# ============================================================================
# Deployment Helpers
# ============================================================================

# Wait for deployment to be available
# Usage: wait_for_deployment <namespace> <deployment> [timeout_seconds]
wait_for_deployment() {
  local namespace="$1"
  local deployment="$2"
  local timeout="${3:-120}"

  $VKDR_KUBECTL wait deployment/"$deployment" \
    -n "$namespace" \
    --for=condition=Available=True \
    --timeout="${timeout}s"
}

# Wait for deployment rollout to complete
# Usage: wait_for_rollout <namespace> <deployment> [timeout_seconds]
wait_for_rollout() {
  local namespace="$1"
  local deployment="$2"
  local timeout="${3:-120}"

  $VKDR_KUBECTL rollout status deployment/"$deployment" \
    -n "$namespace" \
    --timeout="${timeout}s"
}

# Wait for all replicas to be ready
# Usage: wait_for_replicas <namespace> <deployment> [timeout_seconds]
wait_for_replicas() {
  local namespace="$1"
  local deployment="$2"
  local timeout="${3:-120}"

  local end_time=$((SECONDS + timeout))
  while [ $SECONDS -lt $end_time ]; do
    local ready
    ready=$($VKDR_KUBECTL get deployment "$deployment" -n "$namespace" \
      -o jsonpath='{.status.readyReplicas}' 2>/dev/null) || true
    local desired
    desired=$($VKDR_KUBECTL get deployment "$deployment" -n "$namespace" \
      -o jsonpath='{.spec.replicas}' 2>/dev/null) || true

    if [ -n "$ready" ] && [ -n "$desired" ] && [ "$ready" -eq "$desired" ]; then
      return 0
    fi
    echo "# Waiting for replicas: $ready/$desired ready" >&3 2>/dev/null || true
    sleep 3
  done
  return 1
}

# ============================================================================
# Pod Helpers
# ============================================================================

# Wait for pods with label to be ready
# Usage: wait_for_pods <namespace> <label_selector> [timeout_seconds]
wait_for_pods() {
  local namespace="$1"
  local selector="$2"
  local timeout="${3:-90}"

  $VKDR_KUBECTL wait pods \
    -n "$namespace" \
    -l "$selector" \
    --for=condition=Ready \
    --timeout="${timeout}s"
}

# Wait for pod to reach a specific phase
# Usage: wait_for_pod_phase <namespace> <pod_name> <phase> [timeout_seconds]
wait_for_pod_phase() {
  local namespace="$1"
  local pod="$2"
  local phase="$3"
  local timeout="${4:-60}"

  $VKDR_KUBECTL wait pod/"$pod" \
    -n "$namespace" \
    --for=jsonpath='{.status.phase}'="$phase" \
    --timeout="${timeout}s"
}

# Wait for at least N pods with selector
# Usage: wait_for_pod_count <namespace> <selector> <min_count> [timeout_seconds]
wait_for_pod_count() {
  local namespace="$1"
  local selector="$2"
  local min_count="$3"
  local timeout="${4:-60}"

  local end_time=$((SECONDS + timeout))
  while [ $SECONDS -lt $end_time ]; do
    local count
    count=$($VKDR_KUBECTL get pods -n "$namespace" -l "$selector" \
      --no-headers 2>/dev/null | wc -l | tr -d ' ')
    if [ "$count" -ge "$min_count" ]; then
      return 0
    fi
    echo "# Waiting for pods: $count/$min_count" >&3 2>/dev/null || true
    sleep 2
  done
  return 1
}

# ============================================================================
# Service Helpers
# ============================================================================

# Wait for service endpoints to be ready
# Usage: wait_for_endpoints <namespace> <service> [timeout_seconds]
wait_for_endpoints() {
  local namespace="$1"
  local service="$2"
  local timeout="${3:-60}"

  local end_time=$((SECONDS + timeout))
  while [ $SECONDS -lt $end_time ]; do
    local endpoints
    endpoints=$($VKDR_KUBECTL get endpoints "$service" -n "$namespace" \
      -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null) || true
    if [ -n "$endpoints" ]; then
      return 0
    fi
    echo "# Waiting for endpoints on service $service..." >&3 2>/dev/null || true
    sleep 3
  done
  return 1
}

# ============================================================================
# Ingress Helpers
# ============================================================================

# Wait for ingress to have an address
# Usage: wait_for_ingress <namespace> <ingress> [timeout_seconds]
wait_for_ingress() {
  local namespace="$1"
  local ingress="$2"
  local timeout="${3:-60}"

  local end_time=$((SECONDS + timeout))
  while [ $SECONDS -lt $end_time ]; do
    local address
    address=$($VKDR_KUBECTL get ingress "$ingress" -n "$namespace" \
      -o jsonpath='{.status.loadBalancer.ingress[0]}' 2>/dev/null) || true
    if [ -n "$address" ] && [ "$address" != "{}" ]; then
      return 0
    fi
    echo "# Waiting for ingress $ingress to get address..." >&3 2>/dev/null || true
    sleep 3
  done
  return 1
}

# ============================================================================
# Helm Helpers
# ============================================================================

# Wait for helm release to be deployed
# Usage: wait_for_helm_release <namespace> <release> [timeout_seconds]
wait_for_helm_release() {
  local namespace="$1"
  local release="$2"
  local timeout="${3:-120}"

  local end_time=$((SECONDS + timeout))
  while [ $SECONDS -lt $end_time ]; do
    local status
    status=$($VKDR_HELM status "$release" -n "$namespace" -o json 2>/dev/null | \
      $VKDR_JQ -r '.info.status') || true
    if [ "$status" = "deployed" ]; then
      return 0
    fi
    echo "# Waiting for helm release $release: status=$status" >&3 2>/dev/null || true
    sleep 3
  done
  return 1
}

# ============================================================================
# HTTP Helpers
# ============================================================================

# Wait for HTTP endpoint to respond with expected status
# Usage: wait_for_http <url> [expected_code] [timeout_seconds]
wait_for_http() {
  local url="$1"
  local expected_code="${2:-200}"
  local timeout="${3:-60}"

  local end_time=$((SECONDS + timeout))
  while [ $SECONDS -lt $end_time ]; do
    local code
    code=$(curl -s -o /dev/null -w '%{http_code}' "$url" 2>/dev/null) || true
    if [ "$code" = "$expected_code" ]; then
      return 0
    fi
    echo "# Waiting for HTTP $expected_code from $url: got $code" >&3 2>/dev/null || true
    sleep 2
  done
  return 1
}

# Wait for HTTP endpoint to respond (any 2xx)
# Usage: wait_for_http_success <url> [timeout_seconds]
wait_for_http_success() {
  local url="$1"
  local timeout="${2:-60}"

  local end_time=$((SECONDS + timeout))
  while [ $SECONDS -lt $end_time ]; do
    local code
    code=$(curl -s -o /dev/null -w '%{http_code}' "$url" 2>/dev/null) || true
    if [[ "$code" =~ ^2[0-9][0-9]$ ]]; then
      return 0
    fi
    echo "# Waiting for HTTP 2xx from $url: got $code" >&3 2>/dev/null || true
    sleep 2
  done
  return 1
}

# ============================================================================
# CRD Helpers
# ============================================================================

# Wait for CRD to be established
# Usage: wait_for_crd <crd_name> [timeout_seconds]
wait_for_crd() {
  local crd="$1"
  local timeout="${2:-30}"

  $VKDR_KUBECTL wait crd/"$crd" \
    --for=condition=Established \
    --timeout="${timeout}s"
}

# ============================================================================
# Job Helpers
# ============================================================================

# Wait for job to complete
# Usage: wait_for_job <namespace> <job> [timeout_seconds]
wait_for_job() {
  local namespace="$1"
  local job="$2"
  local timeout="${3:-300}"

  $VKDR_KUBECTL wait job/"$job" \
    -n "$namespace" \
    --for=condition=Complete \
    --timeout="${timeout}s"
}

# ============================================================================
# StatefulSet Helpers
# ============================================================================

# Wait for statefulset rollout
# Usage: wait_for_statefulset <namespace> <statefulset> [timeout_seconds]
wait_for_statefulset() {
  local namespace="$1"
  local sts="$2"
  local timeout="${3:-180}"

  $VKDR_KUBECTL rollout status statefulset/"$sts" \
    -n "$namespace" \
    --timeout="${timeout}s"
}

# ============================================================================
# Namespace Helpers
# ============================================================================

# Wait for namespace to be deleted
# Usage: wait_for_namespace_deleted <namespace> [timeout_seconds]
wait_for_namespace_deleted() {
  local namespace="$1"
  local timeout="${2:-120}"

  local end_time=$((SECONDS + timeout))
  while [ $SECONDS -lt $end_time ]; do
    if ! $VKDR_KUBECTL get namespace "$namespace" &>/dev/null; then
      return 0
    fi
    echo "# Waiting for namespace $namespace to be deleted..." >&3 2>/dev/null || true
    sleep 3
  done
  return 1
}
