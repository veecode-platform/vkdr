#!/usr/bin/env bash

# Parameters for remove command
VKDR_MIRROR_HOST=$1

# Source utility scripts
source "$(dirname "$0")/../../.util/log.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"

# Define the path to the mirror registry config file
MIRROR_CONFIG="${HOME}/.vkdr/scripts/.util/configs/mirror-registry.yaml"

# Display information about the command
startInfos() {
  bold "=============================="
  boldInfo "VKDR Registry Mirror Remove"
  bold "=============================="
  boldNotice "Removing mirror for host: ${VKDR_MIRROR_HOST}"
}

# Remove a mirror from the registry config
removeMirror() {
  # Check if the mirror registry config file exists
  if [ ! -f "${MIRROR_CONFIG}" ]; then
    boldError "Mirror registry configuration file not found: ${MIRROR_CONFIG}"
    info "No mirrors are currently configured."
    return 1
  fi
  
  # Export variables for yq to use
  export HOST="\"${VKDR_MIRROR_HOST}\""
  
  # Check if the host exists in the config file
  if ! $VKDR_YQ eval '.mirrors[env(HOST)]' "${MIRROR_CONFIG}" | grep -q "endpoint"; then
    # If the host doesn't exist, show an error
    boldError "Mirror for host ${VKDR_MIRROR_HOST} does not exist."
    return 1
  fi
  
  # Convert hostname to registry name format (replace dots with hyphens)
  MIRROR_NAME="${VKDR_MIRROR_HOST//./-}"
  
  # Check if the registry is running
  REGISTRIES=$($VKDR_K3D registry list -o json | $VKDR_JQ -r '.[].name')
  if echo "$REGISTRIES" | grep -qx "k3d-$MIRROR_NAME"; then
    boldInfo "Stopping registry mirror k3d-$MIRROR_NAME..."
    ${VKDR_K3D} registry delete "k3d-$MIRROR_NAME"
    boldInfo "Registry mirror stopped successfully."
  else
    boldNotice "Registry mirror k3d-$MIRROR_NAME is not running."
  fi
  
  # Remove the mirror from the config file
  $VKDR_YQ eval -i 'del(.mirrors[env(HOST)])' "${MIRROR_CONFIG}"
  boldInfo "Mirror removed successfully from configuration."
  
  # Check if mirrors section is empty and clean up if needed
  if [ "$($VKDR_YQ eval '.mirrors | length' "${MIRROR_CONFIG}")" -eq 0 ]; then
    boldNotice "No more mirrors configured, removing empty mirrors section."
    $VKDR_YQ eval -i 'del(.mirrors)' "${MIRROR_CONFIG}"
  fi
  
  # Unset the exported variables
  unset HOST
}

# Main function to remove a container image mirror
runFormula() {
  startInfos
  
  # Validate input
  if [ -z "${VKDR_MIRROR_HOST}" ]; then
    boldError "Mirror host is required."
    info "Usage: vkdr mirror remove --host <hostname>"
    return 1
  fi
  
  removeMirror
  
  boldInfo "Mirror removal complete."
  boldNotice "Please restart the VKDR infrastructure for changes to take effect:"
  boldNotice "vkdr infra up"
}

# Execute the command
runFormula
