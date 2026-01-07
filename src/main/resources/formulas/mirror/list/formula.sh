#!/usr/bin/env bash

# No parameters needed for list command

# V2 paths: relative to formulas/mirror/list/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

# Source utility scripts
source "$SHARED_DIR/lib/log.sh"
source "$SHARED_DIR/lib/tools-paths.sh"

# Define the path to the mirror registry config file
MIRROR_CONFIG="${HOME}/.vkdr/formulas/_shared/configs/mirror-registry.yaml"

# Display information about the command
startInfos() {
  bold "=============================="
  boldInfo "VKDR Registry Mirror List"
  bold "=============================="
}

parseMirrors() {
  # Check if the mirror registry config file exists
  if [ ! -f "${MIRROR_CONFIG}" ]; then
    boldError "Mirror registry configuration file not found: ${MIRROR_CONFIG}"
    info "No mirrors are currently configured."
    return 1
  fi
  $VKDR_YQ eval '.' "${MIRROR_CONFIG}"
}

# Main function to list container image mirrors
runFormula() {
  startInfos
  parseMirrors
}

# Execute the command
runFormula
