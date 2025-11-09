#!/bin/bash
export VKDR_SCRIPT_HOME="$(pwd)/src/main/resources/scripts"

# Set VKDR_SILENT to false if not set
VKDR_SILENT="${VKDR_SILENT:-false}"
# if any of command line args is "--silent", set VKDR_SILENT=true
if [[ " $* " =~ " --silent " ]]; then
  VKDR_SILENT="true"
fi
#echo "VKDR_SILENT: $VKDR_SILENT"

# Check if VKDR_SILENT is enabled
if [ "${VKDR_SILENT}" = "true" ]; then
  # Silent mode: suppress Maven logs and JVM warnings
  export MAVEN_OPTS="-XX:+IgnoreUnrecognizedVMOptions --add-opens=java.base/sun.misc=ALL-UNNAMED"
  ./mvnw -q exec:java -Dexec.mainClass=codes.vee.vkdr.VkdrApplication -Dexec.args="$*" 2>&1 | grep -v "WARNING:"
else
  # Normal mode: show info
  echo "VKDR_SCRIPT_HOME: $VKDR_SCRIPT_HOME"
  args_string="$*"
  echo "Running VKDR with args: $args_string"
  ./mvnw exec:java -Dexec.mainClass=codes.vee.vkdr.VkdrApplication -Dexec.args="$args_string"
fi
