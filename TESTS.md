# TESTS.md

Comprehensive documentation for VKDR's test infrastructure.

## Overview

VKDR uses the [BATS](https://bats-core.readthedocs.io/) (Bash Automated Testing System) framework for testing formulas. Tests verify that formulas install, configure, and remove resources correctly on a VKDR k3d cluster.

### Library Versions

| Library | Version | Purpose |
| --- | --- | --- |
| bats-core | 1.11.1 | Test framework |
| bats-support | 0.3.0 | Common test helpers |
| bats-assert | 2.1.0 | Assertion functions |
| bats-detik | 1.3.2 | Kubernetes resource assertions |

## Running Tests

### Quick Reference

| Command | Description |
| --- | --- |
| `make test` | Run all formula tests |
| `make test-formula formula=<name>` | Run tests for a specific formula |
| `make test-verbose` | Run tests with verbose output |
| `make test-debug` | Run tests, keep resources on failure |
| `make test-binary` | Run tests against compiled native binary |
| `make test-infra` | Run infra state tests (non-destructive) |
| `make test-infra-lifecycle` | Run infra lifecycle tests (DESTRUCTIVE) |
| `make test-mirror` | Run mirror tests (no cluster required) |
| `make setup-bats` | Download BATS libraries |
| `make clean-bats` | Remove BATS libraries |

### Test Modes

Tests can run in two modes, controlled by `VKDR_TEST_MODE`:

| Mode | Description | When to Use |
| --- | --- | --- |
| `dev` (default) | Maven exec + source formulas | Development - tests current code |
| `binary` | Native binary + extracted formulas | Release - tests compiled binary |

```bash
# Development mode (default)
make test

# Binary mode
VKDR_TEST_MODE=binary make test
# or
make test-binary
```

### Environment Variables

| Variable | Default | Description |
| --- | --- | --- |
| `VKDR_TEST_MODE` | `dev` | Test mode: `dev` or `binary` |
| `VKDR_SKIP_TEARDOWN` | (unset) | Set to `true` to keep resources after test failure |
| `VKDR_TEST_LIFECYCLE` | (unset) | Set to `true` to enable destructive lifecycle tests |
| `BATS_TEST_TIMEOUT` | `300` | Default test timeout in seconds |

## Test Organization

### Directory Structure

```pre
src/test/bats/
├── formulas/
│   └── <service>/
│       ├── install.bats
│       └── remove.bats
├── helpers/
│   ├── common.bash      # Common setup and BATS library loading
│   ├── vkdr.bash        # VKDR CLI and cluster helpers
│   └── k8s-wait.bash    # Kubernetes wait/retry helpers
└── lib/                 # (symlink to .bats-libs)
```

### File Naming Convention

| File | Purpose |
| --- | --- |
| `install.bats` | Tests for formula installation |
| `remove.bats` | Tests for formula removal |
| `cluster.bats` | Cluster state verification (infra) |
| `status.bats` | Status command tests (infra) |
| `lifecycle.bats` | Cluster up/down tests (infra, DESTRUCTIVE) |
| `mirror.bats` | Mirror registry tests |

## Writing Tests

### Test File Template

```bash
#!/usr/bin/env bats
# install.bats - Tests for: vkdr <service> install

load '../../helpers/common'

setup_file() {
  load_vkdr
  configure_detik "vkdr"
  if ! require_vkdr_cluster; then
    skip "VKDR cluster (vkdr-local) not available"
  fi
  # Clean up any previous state
  helm_delete_if_exists "vkdr" "<release>" || true
  sleep 2
}

teardown_file() {
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    helm_delete_if_exists "vkdr" "<release>" || true
  fi
}

@test "<service> install: command succeeds" {
  run vkdr <service> install
  assert_success
  run wait_for_helm_release "vkdr" "<release>" 120
  assert_success
}

@test "<service> install: resources are created" {
  run wait_for_deployment "vkdr" "<deployment>" 120
  assert_success

  run $VKDR_KUBECTL get deployment <deployment> -n vkdr
  assert_success
}
```

### Key Patterns

1. **Always load common helpers**: `load '../../helpers/common'`
2. **Use `setup_file()` for prerequisites**: Check cluster, clean previous state
3. **Use `require_vkdr_cluster()` to skip if no cluster**: Prevents confusing failures
4. **Clean up in `teardown_file()`**: Unless `VKDR_SKIP_TEARDOWN=true`
5. **Use wait helpers for async operations**: Kubernetes resources aren't immediately ready

### Example: Simple Formula Test

From `whoami/install.bats`:

```bash
@test "whoami install: command succeeds" {
  run vkdr whoami install
  assert_success
  run wait_for_helm_release "vkdr" "whoami" 120
  assert_success
}

@test "whoami install: resources are created" {
  run wait_for_deployment "vkdr" "whoami" 120
  assert_success

  # Verify all resources exist
  run $VKDR_KUBECTL get deployment,service,ingress whoami -n vkdr
  assert_success

  # Verify ingress host
  run $VKDR_KUBECTL get ingress whoami -n vkdr -o jsonpath='{.spec.rules[0].host}'
  assert_output "whoami.localhost"
}
```

### Example: Testing JSON Output

From `infra/status.bats`:

```bash
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
```

## Helper Libraries Reference

### common.bash

Main entry point that loads all helpers and BATS libraries.

| Function | Description |
| --- | --- |
| `load_vkdr()` | Initialize VKDR environment (sets `VKDR_FORMULA_HOME`) |
| `configure_detik(namespace)` | Configure bats-detik for Kubernetes assertions |

### vkdr.bash

VKDR CLI and cluster management helpers.

#### Command Execution

| Function | Description |
| --- | --- |
| `vkdr <args...>` | Run a vkdr command (respects `VKDR_TEST_MODE`) |
| `vkdr_silent <args...>` | Run vkdr with `VKDR_SILENT=true` |

#### Cluster Checks

| Function | Description |
| --- | --- |
| `vkdr_cluster_exists()` | Check if vkdr-local cluster exists |
| `vkdr_cluster_running()` | Check if cluster is running |
| `check_vkdr_cluster()` | Comprehensive check (exists, running, context, connection) |
| `require_vkdr_cluster()` | Skip test file if cluster not available |
| `skip_if_no_cluster()` | Skip individual test if no cluster |
| `skip_if_not_vkdr_cluster()` | Skip if not on vkdr-local context |
| `check_vkdr_tools()` | Verify required tools are installed |

#### Helm Utilities

| Function | Description |
| --- | --- |
| `helm_release_exists(namespace, release)` | Check if helm release exists |
| `helm_release_status(namespace, release)` | Get helm release status |
| `helm_delete_if_exists(namespace, release)` | Delete release if it exists |

#### Namespace Utilities

| Function | Description |
| --- | --- |
| `ensure_namespace(namespace)` | Create namespace if it doesn't exist |
| `delete_namespace(namespace)` | Delete namespace (with `--ignore-not-found`) |

#### Tool Paths

Available as environment variables:

- `$VKDR_KUBECTL` - kubectl binary
- `$VKDR_HELM` - helm binary
- `$VKDR_YQ` - yq binary
- `$VKDR_JQ` - jq binary
- `$VKDR_K3D` - k3d binary
- `$VKDR_VAULT` - vault binary

### k8s-wait.bash

Wait/retry helpers for asynchronous Kubernetes operations.

#### Generic

| Function | Description |
| --- | --- |
| `wait_for_condition(max_attempts, sleep_sec, cmd...)` | Retry command until it succeeds |
| `wait_for_output(max_attempts, sleep_sec, expected, cmd...)` | Retry until output matches expected |

#### Deployments

| Function | Description |
| --- | --- |
| `wait_for_deployment(namespace, deployment, [timeout])` | Wait for deployment Available condition |
| `wait_for_rollout(namespace, deployment, [timeout])` | Wait for rollout to complete |
| `wait_for_replicas(namespace, deployment, [timeout])` | Wait for all replicas to be ready |

#### Pods

| Function | Description |
| --- | --- |
| `wait_for_pods(namespace, selector, [timeout])` | Wait for pods with label to be Ready |
| `wait_for_pod_phase(namespace, pod, phase, [timeout])` | Wait for specific pod phase |
| `wait_for_pod_count(namespace, selector, min_count, [timeout])` | Wait for minimum pod count |

#### Services

| Function | Description |
| --- | --- |
| `wait_for_endpoints(namespace, service, [timeout])` | Wait for service to have endpoints |

#### Ingress

| Function | Description |
| --- | --- |
| `wait_for_ingress(namespace, ingress, [timeout])` | Wait for ingress to have an address |

#### Helm

| Function | Description |
| --- | --- |
| `wait_for_helm_release(namespace, release, [timeout])` | Wait for release status "deployed" |

#### CRDs

| Function | Description |
| --- | --- |
| `wait_for_crd(crd_name, [timeout])` | Wait for CRD to be Established |

#### Jobs

| Function | Description |
| --- | --- |
| `wait_for_job(namespace, job, [timeout])` | Wait for job to Complete |

#### StatefulSets

| Function | Description |
| --- | --- |
| `wait_for_statefulset(namespace, sts, [timeout])` | Wait for statefulset rollout |

#### Namespaces

| Function | Description |
| --- | --- |
| `wait_for_namespace_deleted(namespace, [timeout])` | Wait for namespace deletion |

#### HTTP

| Function | Description |
| --- | --- |
| `wait_for_http(url, [expected_code], [timeout])` | Wait for HTTP status code |
| `wait_for_http_success(url, [timeout])` | Wait for any 2xx response |

## Test Conventions

1. **5-6 tests per formula** - Keep tests focused and fast
2. **Assume only cluster is running** - Don't depend on other formulas being installed
3. **Use `$VKDR_*` tool paths** - Never use bare `kubectl`, `helm`, etc.
4. **Idempotent cleanup** - Use `--ignore-not-found` and `|| true` patterns
5. **Namespace deletion for `--all` removal** - Deleting namespace cleans all resources
6. **Test both success and error cases** - Verify error messages when appropriate
7. **Use `--silent` for JSON output tests** - Filters Maven warnings in dev mode
