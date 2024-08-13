#!/bin/bash

args_string="$*"
echo "Running VKDR with args: $args_string"

./mvnw exec:java -Dexec.mainClass=codes.vee.vkdr.VkdrApplication -Dexec.args="$args_string"