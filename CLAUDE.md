# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VKDR (VeeCode Kubernetes Developer Runtime) is a CLI tool to accelerate local Kubernetes development. It's a Spring Boot application compiled to native binary using GraalVM. The architecture is hybrid: Java handles CLI parsing (Picocli), shell scripts handle implementation logic.

## Build Commands

```bash
# Native binary compilation (creates ./target/vkdr)
./mvnw native:compile -Pnative

# Run via Maven (for development)
mvn exec:java -Dexec.mainClass=codes.vee.vkdr.VkdrApplication -Dexec.args="infra up"

# Run tests
./mvnw test

# Suppress Maven memory warnings
export MAVEN_OPTS="--enable-native-access=ALL-UNNAMED --sun-misc-unsafe-memory-access=allow"
```

## Development Mode

Use `VKDR_SCRIPT_HOME` to test script changes without recompiling:

```bash
export VKDR_SCRIPT_HOME=/full/path/to/src/main/resources/scripts
mvn exec:java -Dexec.mainClass=codes.vee.vkdr.VkdrApplication -Dexec.args="kong install -h"
```

## Architecture

**Command Flow:**
1. User runs `vkdr <service> <action>` (e.g., `vkdr kong install`)
2. Picocli parses arguments into Java command class
3. Java calls `ShellExecutor.executeCommand("service/action", args...)`
4. Shell script at `scripts/service/action/formula.sh` executes

**Directory Structure:**
- `src/main/java/codes/vee/vkdr/cmd/` - Picocli command classes organized by service
- `src/main/resources/scripts/` - Shell script implementations
- `src/main/resources/scripts/.util/` - Shared utilities (log.sh, tools-paths.sh)
- `src/main/resources/scripts/.docs/` - Markdown docs for "explain" commands

## Creating New Commands

**ALWAYS use the bootstrap script** - never create commands manually:

```bash
./src/main/resources/scripts/.util/create-command.sh <task> <subtask>
# Example: ./src/main/resources/scripts/.util/create-command.sh metrics collect
```

This creates Java classes, shell script template, and updates ExitCodes.java automatically.

**After running the script, manually:**
1. Add import to `VkdrCommand.java`:
   ```java
   import codes.vee.vkdr.cmd.metrics.VkdrMetricsCommand;
   ```
2. Add to subcommands array in `VkdrCommand.java`:
   ```java
   VkdrMetricsCommand.class,
   ```

## Shell Script Conventions

- Always source utilities: `source "$(dirname "$0")/../../.util/log.sh"`
- Use logging functions: `bold`, `boldInfo`, `boldWarn`, `boldNotice`
- Use tool env vars instead of raw commands: `$VKDR_KUBECTL` not `kubectl`, `$VKDR_YQ` not `yq`
- Parameters come as positional args: `PARAM=$1`

## Exit Codes

Centralized in `src/main/java/codes/vee/vkdr/cmd/common/ExitCodes.java`. Each service has a reserved range (e.g., INFRA 10-19, KONG 20-29). The create-command.sh script handles this automatically.

## Release Process

```bash
# Automated release (sets version, tags, pushes, bumps to next SNAPSHOT)
make release
```

## Java Requirements

- JDK 21 with GraalVM (install via: `sdk install java 24.0.2-graalce`)
