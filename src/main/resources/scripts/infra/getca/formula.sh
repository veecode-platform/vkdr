#!/usr/bin/env bash

VKDR_ENV_INFRA_JSON=$1

# Source common functions and variables
source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

# Define the startInfos function
startInfos() {
  boldInfo "infra getca"
  bold "=============================="
  boldNotice "JSON OUTPUT: $VKDR_ENV_INFRA_JSON"
  bold "=============================="
}

# Define the main function
runFormula() {
    startInfos
    
    # Get CA data from k3d kubeconfig
    debug "Fetching CA data from vkdr-local cluster..."
    CA_DATA=$(k3d kubeconfig get vkdr-local | yq -r '.clusters[0].cluster["certificate-authority-data"]')
    
    if [ -z "$CA_DATA" ]; then
        error "Failed to retrieve CA data from vkdr-local cluster"
        exit 1
    fi
    
    debug "CA data retrieved successfully!"
    # Output CA data in appropriate format
    if [ "$VKDR_ENV_INFRA_JSON" = "true" ]; then
        echo "{\"caData\":\"$CA_DATA\"}"
    else
        echo "$CA_DATA"
    fi
}

# Run the formula
runFormula
