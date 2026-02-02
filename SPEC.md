# SPEC.md

Architecture and design specifications for VKDR.

## Project Overview

VKDR (VeeCode Kubernetes Developer Runtime) is a CLI tool to accelerate local Kubernetes development. It provides commands to manage infrastructure (k3d clusters) and deploy common services (nginx, kong, keycloak, etc.).

## Architecture

### Hybrid Design

```pre
┌─────────────────────────────────────────────────────────────┐
│                      User runs: vkdr whoami install         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Java Layer (Picocli)                     │
│  - CLI parsing and validation                               │
│  - Help text generation                                     │
│  - Argument type conversion (Map, boolean, etc.)            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              ShellExecutor.executeCommand()                 │
│  - Extracts formulas from JAR to temp directory             │
│  - Passes arguments as positional parameters                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 Formula Script (Bash)                       │
│  - formulas/whoami/install/formula.sh                       │
│  - Uses shared libraries from _shared/lib/                  │
│  - Executes kubectl, helm, yq commands                      │
└─────────────────────────────────────────────────────────────┘
```

### Why Hybrid?

- **Java/Picocli**: Excellent CLI UX (help, completion, validation), GraalVM native compilation
- **Bash formulas**: Easy to iterate on Kubernetes operations, readable by DevOps engineers

## Directory Structure

```pre
src/
├── main/
│   ├── java/codes/vee/vkdr/
│   │   ├── VkdrApplication.java      # Entry point
│   │   ├── VkdrCommand.java          # Root command, lists subcommands
│   │   ├── ShellExecutor.java        # Executes formula scripts
│   │   └── cmd/
│   │       ├── common/
│   │       │   ├── ExitCodes.java    # Centralized exit codes
│   │       │   └── CommonDomainMixin.java  # Reusable --domain/--secure options
│   │       ├── whoami/
│   │       │   ├── VkdrWhoamiCommand.java        # Parent: vkdr whoami
│   │       │   ├── VkdrWhoamiInstallCommand.java # vkdr whoami install
│   │       │   └── VkdrWhoamiRemoveCommand.java  # vkdr whoami remove
│   │       └── <service>/...
│   │
│   └── resources/formulas/
│       ├── _shared/
│       │   ├── lib/
│       │   │   ├── log.sh            # Logging functions (bold, boldInfo, etc.)
│       │   │   ├── tools-paths.sh    # Tool path variables ($VKDR_KUBECTL, etc.)
│       │   │   ├── tools-versions.sh # Tool version constants
│       │   │   ├── ingress-tools.sh  # Ingress helper functions
│       │   │   └── gateway-tools.sh  # Gateway API helper functions
│       │   ├── bin/
│       │   │   └── create-command.sh # Bootstrap script for new commands
│       │   └── values/               # Shared helm values
│       │
│       └── <service>/
│           ├── _meta/
│           │   ├── docs.md           # Service documentation (used by explain)
│           │   └── values/           # Service-specific helm values
│           ├── install/
│           │   └── formula.sh
│           ├── remove/
│           │   └── formula.sh
│           └── explain/
│               └── formula.sh        # Usually just displays docs.md
│
└── test/bats/formulas/
    └── <service>/
        ├── install.bats
        └── remove.bats
```

## Java Command Conventions

### Command Structure

```java
@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install service",
        exitCodeOnExecutionException = ExitCodes.SERVICE_INSTALL)
public class VkdrServiceInstallCommand implements Callable<Integer> {

    @CommandLine.Mixin
    private CommonDomainMixin domainSecure;  // Reusable --domain/--secure

    @CommandLine.Option(names = {"--flag"},
        defaultValue = "",
        description = "Flag description")
    private String flag;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("service/install",
            domainSecure.domain,
            String.valueOf(domainSecure.enable_https),
            flag);
    }
}
```

### Exit Codes

Each service has a reserved range in `ExitCodes.java`:

- INFRA: 10-19
- KONG: 20-29
- KEYCLOAK: 30-39
- etc.

## Formula Script Conventions

### Standard Structure

```bash
#!/usr/bin/env bash

# Parameters from Java
PARAM1=$1
PARAM2=$2

# V2 paths
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

# Load libraries
source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

# Constants
SERVICE_NAMESPACE=vkdr

startInfos() {
  boldInfo "Service Install"
  bold "=============================="
  boldNotice "Param1: $PARAM1"
  bold "=============================="
}

runFormula() {
  startInfos
  # ... implementation
}

runFormula
```

### Logging Functions

- `bold "text"` - Bold white text
- `boldInfo "text"` - Bold blue text (headers)
- `boldNotice "text"` - Bold green text (success/info)
- `boldWarn "text"` - Bold yellow text (warnings)
- `debug "text"` - Only shown with --debug flag

### Tool Variables

Never use bare commands. Always use:

- `$VKDR_KUBECTL` instead of `kubectl`
- `$VKDR_HELM` instead of `helm`
- `$VKDR_YQ` instead of `yq`
- `$VKDR_K3D` instead of `k3d`

## Routing: Ingress vs Gateway API

### Ingress (Default)

Uses traditional Kubernetes Ingress resources with ingress controllers (nginx-ingress, traefik).

```bash
source "$SHARED_DIR/lib/ingress-tools.sh"

# Configure ingress in helm values
$VKDR_YQ -i ".ingress.hosts[0].host = \"$HOSTNAME\"" $VALUES_FILE
```

### Gateway API (Optional)

Uses Gateway API resources (Gateway, HTTPRoute) with Gateway controllers (NGINX Gateway Fabric).

```bash
source "$SHARED_DIR/lib/gateway-tools.sh"

# Disable ingress, add HTTPRoute via extraDeploy
configureGatewayRoute "$VALUES_FILE" "$GATEWAY_CLASS" "$HOSTNAME" "$SERVICE" "$PORT" "$NAMESPACE"
```

**Key functions in gateway-tools.sh:**

- `getGatewayByClass` - Find Gateway by gatewayClassName
- `isGatewayClassAvailable` - Check if GatewayClass exists
- `generateHTTPRouteYAML` - Create HTTPRoute manifest
- `configureGatewayRoute` - Main function to configure Gateway routing

**Gateway must allow routes from all namespaces:**

```yaml
listeners:
- name: http
  port: 80
  protocol: HTTP
  allowedRoutes:
    namespaces:
      from: All
```

## Testing Conventions

### BATS Test Structure

```bash
#!/usr/bin/env bats

load '../../helpers/common'

setup_file() {
  load_vkdr
  configure_detik "<namespace>"
  if ! require_vkdr_cluster; then
    skip "VKDR cluster not available"
  fi
  # Clean state
  helm_delete_if_exists "<namespace>" "<release>" || true
}

teardown_file() {
  if [ "${VKDR_SKIP_TEARDOWN:-}" != "true" ]; then
    helm_delete_if_exists "<namespace>" "<release>" || true
  fi
}

@test "service install: command succeeds" {
  run vkdr service install
  assert_success
}

@test "service install: resources are created" {
  # Verify resources exist
  run $VKDR_KUBECTL get deployment,service -n <namespace>
  assert_success
}
```

### Test Guidelines

1. **Keep tests simple** - 5-6 tests per formula maximum
2. **Assume minimal prerequisites** - Only cluster running, no specific controllers
3. **Combine related checks** - One test can verify multiple resources
4. **Use helper functions** - `wait_for_deployment`, `wait_for_rollout`, etc.

## Idempotency Requirements

All remove operations must be idempotent (safe to run multiple times).

### Patterns

```bash
# Helm: check before delete
if $VKDR_HELM list -n <ns> -q | grep -q "<release>"; then
  $VKDR_HELM delete <release> -n <ns>
fi

# Kubectl: use --ignore-not-found
$VKDR_KUBECTL delete gateway nginx -n nginx-gateway --ignore-not-found

# Full cleanup: delete namespace
$VKDR_KUBECTL delete namespace <ns> --ignore-not-found
```

### Remove Flag Conventions

- Default remove: Only remove the main resource (Gateway, not control plane)
- `--all` or `--delete-<component>`: Full removal including dependencies

## Release Process

```bash
make release
```

This:

1. Sets version (removes -SNAPSHOT)
2. Generates changelog from commits
3. Commits and tags
4. Pushes tag and main
5. Bumps to next -SNAPSHOT version

## Java Requirements

- JDK 21 with GraalVM
- Install: `sdk install java 24.0.2-graalce`
