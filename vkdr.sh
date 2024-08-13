#!/bin/bash

./mvnw exec:java -Dexec.mainClass=codes.vee.vkdr.VkdrApplication -Dexec.args="$@"