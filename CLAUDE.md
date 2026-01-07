# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VKDR (VeeCode Kubernetes Developer Runtime) is a CLI tool to accelerate local Kubernetes development. It's a Spring Boot application compiled to native binary using GraalVM. The architecture is hybrid: Java handles CLI parsing (Picocli), shell scripts (formulas) handle implementation logic.

## Build Commands

```bash
# Native binary compilation (creates ./target/vkdr)
./mvnw native:compile -Pnative

# Run via Maven (for development)
mvn exec:java -Dexec.mainClass=codes.vee.vkdr.VkdrApplication -Dexec.args="infra up"

# Run tests (Java unit tests)
./mvnw test

# Run formula tests (BATS)
make test              # All formula tests
make test-whoami       # Just whoami tests
make test-formula formula=kong  # Specific formula

# Suppress Maven memory warnings
export MAVEN_OPTS="--enable-native-access=ALL-UNNAMED --sun-misc-unsafe-memory-access=allow"
```

## Development Mode

Use `VKDR_FORMULA_HOME` to test formula changes without recompiling:

```bash
export VKDR_FORMULA_HOME=/full/path/to/src/main/resources/formulas
mvn exec:java -Dexec.mainClass=codes.vee.vkdr.VkdrApplication -Dexec.args="whoami install -h"
```

## Architecture (V2)

**Command Flow:**
1. User runs `vkdr <service> <action>` (e.g., `vkdr whoami install`)
2. Picocli parses arguments into Java command class
3. Java calls `ShellExecutor.executeCommand("service/action", args...)`
4. Formula script at `formulas/service/action/formula.sh` executes

**Directory Structure (V2):**
```
src/main/resources/formulas/
├── _shared/                    # Shared utilities and configs
│   ├── lib/                    # Shell libraries (log.sh, tools-paths.sh, etc.)
│   ├── bin/                    # Utility scripts (create-command.sh, etc.)
│   ├── values/                 # Helm values templates
│   ├── operators/              # Kubernetes operator manifests
│   └── configs/                # Miscellaneous configs
├── whoami/                     # Service: whoami
│   ├── _meta/
│   │   ├── docs.md            # Service documentation
│   │   └── values/            # Service-specific helm values
│   ├── install/
│   │   └── formula.sh         # Install implementation
│   └── remove/
│       └── formula.sh         # Remove implementation
└── kong/                       # Service: kong (and other services...)
    └── ...
```

**Java Command Classes:**
- `src/main/java/codes/vee/vkdr/cmd/` - Picocli command classes organized by service

## Creating New Commands

**ALWAYS use the bootstrap script** - never create commands manually:

```bash
./src/main/resources/formulas/_shared/bin/create-command.sh <task> <subtask>
# Example: ./src/main/resources/formulas/_shared/bin/create-command.sh metrics collect
```

This creates Java classes, formula template, and updates ExitCodes.java automatically.

**After running the script, manually:**
1. Add import to `VkdrCommand.java`:
   ```java
   import codes.vee.vkdr.cmd.metrics.VkdrMetricsCommand;
   ```
2. Add to subcommands array in `VkdrCommand.java`:
   ```java
   VkdrMetricsCommand.class,
   ```

## Formula Script Conventions (V2)

- **Path to shared libs:** `source "$FORMULA_DIR/../../_shared/lib/log.sh"`
- **Standard preamble:**
  ```bash
  FORMULA_DIR="$(dirname "$0")"
  SHARED_DIR="$FORMULA_DIR/../../_shared"
  META_DIR="$FORMULA_DIR/../_meta"

  source "$SHARED_DIR/lib/tools-versions.sh"
  source "$SHARED_DIR/lib/tools-paths.sh"
  source "$SHARED_DIR/lib/log.sh"
  ```
- Use logging functions: `bold`, `boldInfo`, `boldWarn`, `boldNotice`
- Use tool env vars: `$VKDR_KUBECTL` not `kubectl`, `$VKDR_YQ` not `yq`
- Parameters come as positional args: `PARAM=$1`

## Testing with BATS

Formula tests use BATS (Bash Automated Testing System):

```bash
# Setup BATS (first time only)
make setup-bats

# Run all tests
make test

# Run specific formula tests
make test-whoami
make test-formula formula=kong

# Debug mode (keep resources on failure)
make test-debug
```

**Test location:** `src/test/bats/formulas/<service>/<action>.bats`

**Tests serve as documentation:** Use `@doc:` and `@example:` annotations in tests.

## Exit Codes

Centralized in `src/main/java/codes/vee/vkdr/cmd/common/ExitCodes.java`. Each service has a reserved range (e.g., INFRA 10-19, KONG 20-29). The create-command.sh script handles this automatically.

## Release Process

```bash
# Automated release (sets version, tags, pushes, bumps to next SNAPSHOT)
make release
```

## Java Requirements

- JDK 21 with GraalVM (install via: `sdk install java 24.0.2-graalce`)
