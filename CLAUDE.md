# CLAUDE.md

Quick reference for Claude Code when working with this repository. For architecture details, see [SPEC.md](SPEC.md).

## Quick Commands

```bash
# Compile and run (development)
export MAVEN_OPTS="--enable-native-access=ALL-UNNAMED --sun-misc-unsafe-memory-access=allow"
export VKDR_FORMULA_HOME=$(pwd)/src/main/resources/formulas
mvn compile -q && mvn -q exec:java -Dexec.mainClass=codes.vee.vkdr.VkdrApplication -Dexec.args="<command>"

# Native binary (release)
./mvnw native:compile -Pnative

# Tests
make test                         # All formula tests
make test-formula formula=whoami  # Specific formula

# Release
make release
```

## Creating New Commands

**ALWAYS use the bootstrap script:**

```bash
./src/main/resources/formulas/_shared/bin/create-command.sh <service> <action>
```

Then manually add to `VkdrCommand.java`:
```java
import codes.vee.vkdr.cmd.<service>.Vkdr<Service>Command;
// ...
subcommands = { ..., Vkdr<Service>Command.class }
```

## Key Conventions

1. **Tool paths**: Use `$VKDR_KUBECTL`, `$VKDR_HELM`, `$VKDR_YQ` - never bare commands
2. **Idempotency**: All remove operations must be safe to run multiple times
3. **Namespace cleanup**: Use namespace deletion for `--all` removal, not individual resources
4. **Tests**: Keep simple (5-6 tests per formula), assume only cluster is running
5. **Docs**: Each formula has `_meta/docs.md` (user docs) and `_meta/spec.md` (implementation spec)

## Before Modifying a Formula

**Always read `_meta/spec.md` first** - it contains architecture decisions, known bugs, and implementation notes specific to that formula.

## Updating Formulas

Each formula with external dependencies has documentation for keeping it up-to-date:

- **Human-readable**: `_meta/spec.md` contains an "Updating" section describing the update process
- **Machine-readable**: `_meta/update.yaml` defines the update configuration for automation

Update types in `update.yaml`:

| Type | Meaning |
|------|---------|
| `helm-pinned` | Version is pinned in formula - check for new chart versions |
| `helm-latest` | Uses latest chart version - tests catch breaking changes |
| `helm-frozen` | Do not update (deprecated/dead upstream project) |
| `operator` | Operator manifest from GitHub releases - download new versions |

Formulas without `update.yaml` (init, upgrade, infra, mirror) have no external dependencies to track.

## File Locations

| What | Where |
|------|-------|
| Java commands | `src/main/java/codes/vee/vkdr/cmd/<service>/` |
| Formula scripts | `src/main/resources/formulas/<service>/<action>/formula.sh` |
| Shared libraries | `src/main/resources/formulas/_shared/lib/` |
| Helm values | `src/main/resources/formulas/<service>/_meta/values/` |
| User documentation | `src/main/resources/formulas/<service>/_meta/docs.md` |
| Implementation spec | `src/main/resources/formulas/<service>/_meta/spec.md` |
| Update config | `src/main/resources/formulas/<service>/_meta/update.yaml` |
| BATS tests | `src/test/bats/formulas/<service>/<action>.bats` |

## Common Patterns

### Formula Preamble
```bash
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"
```

### Idempotent Remove
```bash
# Check before helm delete
if $VKDR_HELM list -n <ns> -q | grep -q "<release>"; then
  $VKDR_HELM delete <release> -n <ns>
fi

# Use --ignore-not-found for kubectl
$VKDR_KUBECTL delete <resource> --ignore-not-found

# For full cleanup, delete namespace (when not shared)
$VKDR_KUBECTL delete namespace <ns> --ignore-not-found
```

### Gateway API Support
```bash
source "$SHARED_DIR/lib/gateway-tools.sh"

if [ -n "$GATEWAY_CLASS" ]; then
  configureGatewayRoute "$VALUES_FILE" "$GATEWAY_CLASS" "$HOSTNAME" "$SERVICE" "$PORT" "$NAMESPACE"
fi
```
