#!/usr/bin/env bash

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

runFormula() {
  explainVault
}

explainVault() {
  $VKDR_GLOW -p "$(dirname "$0")/../../.docs/VAULT.md"
}

runFormula
