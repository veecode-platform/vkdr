#!/usr/bin/env bash

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

runFormula() {
  explain
}

explain() {
  $VKDR_GLOW -p "$(dirname "$0")/../../.docs/POSTGRES.md"
}

runFormula
