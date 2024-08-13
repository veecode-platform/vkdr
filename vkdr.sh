#!/bin/bash
export VKDR_SCRIPT_HOME="$(pwd)/src/main/resources/scripts"
echo "VKDR_SCRIPT_HOME: $VKDR_SCRIPT_HOME"
args_string="$*"
echo "Running VKDR with args: $args_string"

./mvnw exec:java -Dexec.mainClass=codes.vee.vkdr.VkdrApplication -Dexec.args="$args_string"