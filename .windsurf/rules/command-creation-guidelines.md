---
trigger: always_on
description: when asked to create a new command for vkdr CLI
---

# VKDR Command Creation Guidelines

## 🚀 ALWAYS Use the create-command.sh Script

When creating new VKDR commands, **NEVER** manually create files. Always use the bootstrap script:

```bash
./src/main/resources/scripts/.util/create-command.sh <task> <subtask>
```

### Why This Script is Mandatory

1. **Consistency**: Ensures all commands follow the exact same structure
2. **Exit Code Management**: Automatically assigns unique exit codes
3. **Package Structure**: Creates correct Java package hierarchy
4. **Dependencies**: Handles all imports and class registrations
5. **Shell Scripts**: Generates formula.sh with proper sourcing

## The Script Does Everything

For example, when you run `./create-command.sh metrics collect`, it creates:

### Java Files

- `src/main/java/codes/vee/vkdr/cmd/metrics/VkdrMetricsCommand.java`
- `src/main/java/codes/vee/vkdr/cmd/metrics/VkdrMetricsCollectCommand.java`

### Shell Script

- `src/main/resources/scripts/metrics/collect/formula.sh`

### Exit Codes

- Adds `METRICS_BASE` and `METRICS_COLLECT` to `ExitCodes.java`
- Updates the `// NEXT:` counter

## Manual Steps Required (Only 2)

After running the script, you only need to:

1. **Add import** to `src/main/java/codes/vee/vkdr/cmd/VkdrCommand.java`:

```java
import codes.vee.vkdr.cmd.metrics.VkdrMetricsCommand;
```

1. **Add subcommand** to the subcommands array in `VkdrCommand.java`:

```java
VkdrMetricsCommand.class,
```

## Example Workflow

```bash
# 1. Create the command structure
./src/main/resources/scripts/.util/create-command.sh metrics collect

# 2. Add import to VkdrCommand.java
echo "import codes.vee.vkdr.cmd.metrics.VkdrMetricsCommand;" >> src/main/java/codes/vee/vkdr/cmd/VkdrCommand.java

# 3. Add to subcommands list (edit manually)
# Open VkdrCommand.java and add "VkdrMetricsCommand.class," to the subcommands array
```

## Command Naming Convention

- **Task**: Service name (lowercase) - `kong`, `postgres`, `infra`
- **Subtask**: Action (lowercase) - `install`, `remove`, `start`, `list`
- **Java Classes**: `Vkdr{Task}Command.java`, `Vkdr{Task}{Subtask}Command.java`

## Never Do This Manually

❌ Don't create Java files manually  
❌ Don't edit ExitCodes.java manually  
❌ Don't create shell scripts manually  
❌ Don't figure out exit codes yourself  

## Always Do This

✅ Use `create-command.sh <task> <subtask>`  
✅ Add the import to VkdrCommand.java  
✅ Add the class to subcommands array  
✅ Implement your logic in the generated formula.sh  

This ensures consistency, maintainability, and proper integration with the VKDR CLI framework.

You can always complete the code created to fit the task asked by a prompt.