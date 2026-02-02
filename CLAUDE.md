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

# Tests (see TESTS.md for full documentation)
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
4. **Tests**: See [TESTS.md](TESTS.md) for test patterns and conventions
5. **Docs**: Each formula has `_meta/docs.md` (user docs) and `_meta/spec.md` (implementation spec)

## Markdown Style

- **Headings**: Always add a blank line after headings
- **Code blocks**: Use `pre` when no language applies (never leave ` ``` ` without a language)
- **Tables**: Use spaced dividers `| --- | --- |` not `|-----|-----|` (when fixing try to leave it with the same width as before)

## Before Modifying a Formula

**Always read `_meta/spec.md` first** - it contains architecture decisions, known bugs, and implementation notes specific to that formula.

## Updating Formulas

Each formula with external dependencies has documentation for keeping it up-to-date:

- **Human-readable**: `_meta/spec.md` contains an "Updating" section describing the update process
- **Machine-readable**: `_meta/update.yaml` defines the update configuration for automation

Update types in `update.yaml`:

| Type | Meaning |
| --- | --- |
| `helm-pinned` | Version is pinned in formula - check for new chart versions |
| `helm-latest` | Uses latest chart version - tests catch breaking changes |
| `helm-frozen` | Do not update (deprecated/dead upstream project) |
| `operator` | Operator manifest from GitHub releases - download new versions |

Formulas without `update.yaml` (init, upgrade, infra, mirror) have no external dependencies to track.

## File Locations

| What | Where |
| --- | --- |
| Java commands | `src/main/java/codes/vee/vkdr/cmd/<service>/` |
| Formula scripts | `src/main/resources/formulas/<service>/<action>/formula.sh` |
| Shared libraries | `src/main/resources/formulas/_shared/lib/` |
| Helm values | `src/main/resources/formulas/<service>/_meta/values/` |
| User documentation | `src/main/resources/formulas/<service>/_meta/docs.md` |
| Implementation spec | `src/main/resources/formulas/<service>/_meta/spec.md` |
| Update config | `src/main/resources/formulas/<service>/_meta/update.yaml` |
| Default mirror config | `src/main/resources/formulas/_shared/configs/mirror-registry.yaml` |
| User mirror config | `~/.vkdr/configs/mirror-registry.yaml` |

## Default Mirror Registries

The cluster is configured with mirrors for common container registries to avoid rate limits and speed up pulls:

| Registry | Port | Purpose |
| --- | --- | --- |
| `docker.io` | 6001 | Docker Hub - has strict rate limits (100 pulls/6h anonymous) |
| `registry.k8s.io` | 6002 | Kubernetes images (replaces k8s.gcr.io) |
| `ghcr.io` | 6003 | GitHub Container Registry |

**Config locations:**

- Default template: `src/main/resources/formulas/_shared/configs/mirror-registry.yaml`
- User config: `~/.vkdr/configs/mirror-registry.yaml` (copied on first `vkdr init`, preserved on subsequent runs)

Users can add/remove mirrors with `vkdr mirror add --host <registry>` and `vkdr mirror remove --host <registry>`.

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
