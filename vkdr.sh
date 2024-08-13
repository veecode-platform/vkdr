#!/bin/bash

#echo all parameters
./mvnw exec:java -Dexec.mainClass=codes.vee.vkdr.VkdrApplication -Dexec.args="$@"