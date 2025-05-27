#!/usr/bin/env bash

# Parameters for add command
VKDR_MIRROR_HOST=$1

# Source utility scripts
source "$(dirname "$0")/../../.util/log.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"

# Define the path to the mirror registry config file
MIRROR_CONFIG="${HOME}/.vkdr/scripts/.util/configs/mirror-registry.yaml"

# Display information about the command
startInfos() {
  bold "=============================="
  boldInfo "VKDR Registry Mirror Add"
  bold "=============================="
  boldNotice "Adding mirror for host: ${VKDR_MIRROR_HOST}"
}

# Add a mirror to the registry config
addMirror() {
  # Check if the mirror registry config file exists
  if [ ! -f "${MIRROR_CONFIG}" ]; then
    notice "Mirror registry configuration file not found. Creating a new one."
    mkdir -p "$(dirname "${MIRROR_CONFIG}")"
    echo "mirrors:" > "${MIRROR_CONFIG}"
  fi
  
  # Find the highest endpoint port number to create an incremental one
  local highest_port=6000
  # Use yq to find the highest endpoint port
  local endpoints=$($VKDR_YQ eval '.mirrors.*.endpoint[]' "${MIRROR_CONFIG}" 2>/dev/null | grep -o '[0-9]*' || echo "6000")
  for port in $endpoints; do
    if [ "$port" -gt "$highest_port" ]; then
      highest_port=$port
    fi
  done
  
  # Increment the endpoint port
  local new_port=$((highest_port + 1))
  
  # Create the endpoint URL
  local endpoint_url="http://host.k3d.internal:${new_port}"
  
  # Export variables for yq to use
  export HOST="\"${VKDR_MIRROR_HOST}\""
  export ENDPOINT="${endpoint_url}"
  
  # Add the new mirror to the config file
  if $VKDR_YQ eval '.mirrors[env(HOST)]' "${MIRROR_CONFIG}" | grep -q "endpoint"; then
    # If the host already exists, ignores
    boldInfo "Mirror for host ${VKDR_MIRROR_HOST} already exists, ignoring."
  else
    # If the host doesn't exist, create a new entry
    $VKDR_YQ eval -i '.mirrors[env(HOST)].endpoint = [env(ENDPOINT)]' "${MIRROR_CONFIG}"
    boldInfo "Mirror added successfully, please restart VKDR"
    boldNotice "Host: ${VKDR_MIRROR_HOST}"
    boldNotice "Endpoint: ${endpoint_url}"
  fi
  
  # Unset the exported variables
  unset HOST
  unset ENDPOINT
  
}

# Main function to add a container image mirror
runFormula() {
  startInfos
  
  # Validate input
  if [ -z "${VKDR_MIRROR_HOST}" ]; then
    boldError "Mirror host is required."
    info "Usage: vkdr mirror add <host>"
    return 1
  fi
  
  addMirror
  
  boldInfo "Done."
}

# Execute the command
runFormula
