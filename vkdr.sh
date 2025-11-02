#!/bin/bash
export VKDR_SCRIPT_HOME="$(pwd)/src/main/resources/scripts"

# Check if VKDR_SILENT is enabled
if [ "${VKDR_SILENT:-false}" = "true" ]; then
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