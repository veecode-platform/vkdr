#!/usr/bin/env bash

# Exit on error
set -e

# Check if required arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <task> <subtask>"
    exit 1
fi

TASK=$(echo "$1" | tr '[:upper:]' '[:lower:]')
SUBTASK=$(echo "$2" | tr '[:upper:]' '[:lower:]')

# Handle hyphens: convert to underscore for package/directory names
TASK_UNDERSCORE=$(echo "$TASK" | tr '-' '_')
SUBTASK_UNDERSCORE=$(echo "$SUBTASK" | tr '-' '_')

# Convert hyphen-separated to CamelCase for class names
to_camel_case() {
    local input="$1"
    local result=""
    local capitalize_next=true
    for (( i=0; i<${#input}; i++ )); do
        local char="${input:$i:1}"
        if [[ "$char" == "-" || "$char" == "_" ]]; then
            capitalize_next=true
        elif $capitalize_next; then
            result+=$(echo "$char" | tr '[:lower:]' '[:upper:]')
            capitalize_next=false
        else
            result+="$char"
        fi
    done
    echo "$result"
}
TASK_CAMEL=$(to_camel_case "$TASK")
SUBTASK_CAMEL=$(to_camel_case "$SUBTASK")

# Upper case with underscores for exit codes
TASK_UPPER_CASE=$(echo "$TASK_UNDERSCORE" | tr '[:lower:]' '[:upper:]')
SUBTASK_UPPER_CASE=$(echo "$SUBTASK_UNDERSCORE" | tr '[:lower:]' '[:upper:]')

# Get script and project directories
SCRIPT_DIR="$(dirname "$0")/../.."
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JAVA_BASE="${SCRIPT_ROOT}/../../../../java/codes/vee/vkdr/cmd"
JAVA_BASE="$(cd "${JAVA_BASE}" && pwd)"
JAVA_PACKAGE="codes.vee.vkdr.cmd.${TASK_UNDERSCORE}"
JAVA_DIR="${JAVA_BASE}/${TASK_UNDERSCORE}"
TARGET_DIR="${SCRIPT_DIR}/${TASK}/${SUBTASK}"
EXIT_CODES_FILE="${JAVA_BASE}/common/ExitCodes.java"

# Get the next available exit code number
get_next_exit_code() {
    # Read the NEXT number from the comment at the top of the file
    local next_code=$(grep -m 1 '^// NEXT: \([0-9]\+\)' "$EXIT_CODES_FILE" | grep -o '[0-9]\+')
    if [ -z "$next_code" ]; then
        echo "Error: Could not find '// NEXT: <number>' comment in $EXIT_CODES_FILE"
        exit 1
    fi
    echo $next_code
}

# Update the NEXT number in the ExitCodes file
update_next_exit_code() {
    local new_next=$(($1 + 10))
    sed -i '' "s|^// NEXT: .*|// NEXT: ${new_next}|" "$EXIT_CODES_FILE"
}

# Add exit codes to ExitCodes.java
add_exit_codes() {
    local base_code=$1
    local task_upper=$2
    local subtask_upper=$3
    
    # Add BASE constant if it doesn't exist
    if ! grep -q "public static final int ${task_upper}_BASE" "$EXIT_CODES_FILE"; then
        # Add new task block before the ADD_HERE comment
        local new_block="// ${task_upper} related exit codes ($((base_code))-$((base_code+9)))\n"
        new_block+="    public static final int ${task_upper}_BASE = ${base_code};\n"
        new_block+="    public static final int ${task_upper}_${subtask_upper} = $((base_code + 1));\n\n    // ADD_HERE"
        
        sed -i '' "s|// ADD_HERE|${new_block}|" "$EXIT_CODES_FILE"
        
        # Update the NEXT number
        update_next_exit_code $base_code
    elif ! grep -q "public static final int ${task_upper}_${subtask_upper}" "$EXIT_CODES_FILE"; then
        # Add subtask constant to existing task
        local new_constant="    public static final int ${task_upper}_${subtask_upper} = $((base_code + 1));"
        sed -i '' "/public static final int ${task_upper}_BASE/ {n; s|^|${new_constant}\n|; }" "$EXIT_CODES_FILE"
    fi
}

# Create the script directory
mkdir -p "${TARGET_DIR}"

# Create Java package directory
mkdir -p "${JAVA_DIR}"

# Create or update Java command class
generate_java_command_class() {
    local class_name="Vkdr${TASK_CAMEL}Command"
    local file_path="${JAVA_DIR}/${class_name}.java"
    local subcommand_class="Vkdr${TASK_CAMEL}${SUBTASK_CAMEL}Command"

    # Get the next available exit code
    local base_code=$(get_next_exit_code)
    local exit_code_constant="${TASK_UPPER_CASE}_BASE"

    # Add exit codes to ExitCodes.java
    add_exit_codes $base_code "${TASK_UPPER_CASE}" "${SUBTASK_UPPER_CASE}"

    # Update the exit code constant to use the actual code
    exit_code_constant="${TASK_UPPER_CASE}_BASE"

    if [ -f "$file_path" ]; then
        # If file exists, check if the subcommand is already in the subcommands list
        if ! grep -q "$subcommand_class" "$file_path"; then
            # Add the new subcommand before the ADD_HERE comment
            sed -i '' "s|// ADD_HERE|// ADD_HERE\n            ${subcommand_class}.class,|" "$file_path"
            echo "Added subcommand ${subcommand_class} to ${file_path}"
        else
            echo "Subcommand ${subcommand_class} already exists in ${file_path}"
        fi
    else
        # Create new command class
        cat > "${file_path}" << EOF
package codes.vee.vkdr.cmd.${TASK_UNDERSCORE};

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
@CommandLine.Command(name = "${TASK}", mixinStandardHelpOptions = true,
        exitCodeOnExecutionException = ExitCodes.${exit_code_constant},
        description = "manage ${TASK} service",
        subcommands = {
            // ADD_HERE
            ${subcommand_class}.class
        })
public class ${class_name} {
}
EOF
        echo "Created Java command class: ${file_path}"
    fi
}

# Create Java subcommand class
generate_java_subcommand_class() {
    local class_name="Vkdr${TASK_CAMEL}${SUBTASK_CAMEL}Command"
    local file_path="${JAVA_DIR}/${class_name}.java"

    # The exit code constant will be set by the command class
    local exit_code_constant="${TASK_UPPER_CASE}_${SUBTASK_UPPER_CASE}"

    cat > "${file_path}" << EOF
package codes.vee.vkdr.cmd.${TASK_UNDERSCORE};

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "${SUBTASK}", mixinStandardHelpOptions = true,
        description = "${SUBTASK} ${TASK} service",
        exitCodeOnExecutionException = ExitCodes.${exit_code_constant})
public class ${class_name} implements Callable<Integer> {

    @CommandLine.Option(names = {"--arg1"},
            description = "Example argument",
            defaultValue = "")
    private String arg1;

    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("${TASK}/${SUBTASK}", arg1);
    }
}
EOF

    echo "Created Java subcommand class: ${file_path}"
}

# Generate Java classes
generate_java_command_class
generate_java_subcommand_class

# Create formula.sh with basic structure
cat > "${TARGET_DIR}/formula.sh" << EOF
#!/usr/bin/env bash

VKDR_ENV_${TASK_UPPER_CASE}_ARG1=\$1

# Source common functions and variables
source "\$(dirname "\$0")/../../_shared/lib/tools-versions.sh"
source "\$(dirname "\$0")/../../_shared/lib/tools-paths.sh"
source "\$(dirname "\$0")/../../_shared/lib/log.sh"

# Define the startInfos function
startInfos() {
  boldInfo "${TASK} ${SUBTASK}"
  bold "=============================="
  boldNotice "ARG1: $VKDR_ENV_${TASK_UPPER_CASE}_ARG1"
  bold "=============================="
}

# Define the main function
runFormula() {
    startInfos
    # Add your command logic here
}

# Run the formula
runFormula
EOF

# Make the script executable
chmod +x "${TARGET_DIR}/formula.sh"

echo "Created command structure for 'vkdr ${TASK} ${SUBTASK}' in ${TARGET_DIR}"
echo "Please add the following import to VkdrCommand.java if not already present:"
echo "import ${JAVA_PACKAGE}.Vkdr${TASK_CAMEL}Command;"
echo "And add 'Vkdr${TASK_CAMEL}Command.class' to the subcommands list in VkdrCommand.java"
