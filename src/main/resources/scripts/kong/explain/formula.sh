#!/usr/bin/env bash

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

runFormula() {
  explainKong
}

explainKong() {
  $VKDR_GLOW -p "$(dirname "$0")/../../.docs/KONG.md"
}

runFormula
