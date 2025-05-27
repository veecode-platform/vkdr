#!/usr/bin/env bash

# No parameters needed for list command

# Source utility scripts
source "$(dirname "$0")/../../.util/log.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"

# Define the path to the mirror registry config file
MIRROR_CONFIG="${HOME}/.vkdr/scripts/.util/configs/mirror-registry.yaml"

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
