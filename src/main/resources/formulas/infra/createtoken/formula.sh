#!/usr/bin/env bash

VKDR_ENV_INFRA_DURATION=$1
VKDR_ENV_INFRA_JSON=$2

# V2 paths: relative to formulas/infra/createtoken/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

# Define the startInfos function
startInfos() {
  boldInfo "infra createtoken"
  bold "=============================="
  boldNotice "DURATION: $VKDR_ENV_INFRA_DURATION"
  bold "=============================="
}

# Define the main function
runFormula() {
    startInfos

    # Create service account named api-client
    debug "Creating service account 'api-client'..."
    if [ "$VKDR_SILENT" = "true" ]; then
        kubectl create serviceaccount api-client --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1
    else
        kubectl create serviceaccount api-client --dry-run=client -o yaml | kubectl apply -f -
    fi

    # Create cluster role binding for api-client with cluster-admin role
    debug "Binding 'api-client' service account to cluster-admin role..."
    if [ "$VKDR_SILENT" = "true" ]; then
        kubectl create clusterrolebinding api-client-cluster-admin \
            --clusterrole=cluster-admin \
            --serviceaccount=default:api-client \
            --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1
    else
        kubectl create clusterrolebinding api-client-cluster-admin \
            --clusterrole=cluster-admin \
            --serviceaccount=default:api-client \
            --dry-run=client -o yaml | kubectl apply -f -
    fi

    # Create token with specified duration
    debug "Creating token with duration '$VKDR_ENV_INFRA_DURATION'..."
    TOKEN=$(kubectl create token api-client --duration="$VKDR_ENV_INFRA_DURATION")

    debug "Token created successfully!"
    # Output token in appropriate format
    if [ "$VKDR_ENV_INFRA_JSON" = "true" ]; then
        echo "{\"token\":\"$TOKEN\"}"
    else
        echo "$TOKEN"
    fi
}

# Run the formula
runFormula
