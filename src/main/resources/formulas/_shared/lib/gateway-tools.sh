#!/usr/bin/env bash

#
# Gateway API tools for VKDR formulas
#

# getGatewayByClass: finds a Gateway by its gatewayClassName
# Returns the gateway name and namespace as "name:namespace" or empty if not found
getGatewayByClass() {
  local GATEWAY_CLASS=$1
  if [ -z "$GATEWAY_CLASS" ]; then
    debug "getGatewayByClass: error, must inform a gateway class"
    return 1
  fi
  debug "getGatewayByClass: looking for gateway with class '$GATEWAY_CLASS'"

  # Find gateway by class across all namespaces
  local RESULT=$($VKDR_KUBECTL get gateway -A -o jsonpath="{range .items[?(@.spec.gatewayClassName=='$GATEWAY_CLASS')]}{.metadata.name}:{.metadata.namespace}{'\n'}{end}" 2>/dev/null | head -n 1)

  if [ -z "$RESULT" ]; then
    debug "getGatewayByClass: no gateway found for class '$GATEWAY_CLASS'"
    return 1
  fi

  debug "getGatewayByClass: found gateway '$RESULT'"
  echo "$RESULT"
}

# isGatewayClassAvailable: checks if a GatewayClass exists
isGatewayClassAvailable() {
  local GATEWAY_CLASS=$1
  if [ -z "$GATEWAY_CLASS" ]; then
    debug "isGatewayClassAvailable: error, must inform a gateway class"
    return 1
  fi
  $VKDR_KUBECTL get gatewayclass "$GATEWAY_CLASS" &>/dev/null
}

# generateHTTPRouteYAML: generates HTTPRoute YAML for extraDeploy
# Arguments: name, namespace, gateway_name, gateway_namespace, hostname, service_name, service_port
generateHTTPRouteYAML() {
  local NAME=$1
  local NAMESPACE=$2
  local GATEWAY_NAME=$3
  local GATEWAY_NAMESPACE=$4
  local HOSTNAME=$5
  local SERVICE_NAME=$6
  local SERVICE_PORT=$7

  cat <<EOF
- apiVersion: gateway.networking.k8s.io/v1
  kind: HTTPRoute
  metadata:
    name: $NAME
    namespace: $NAMESPACE
  spec:
    parentRefs:
    - name: $GATEWAY_NAME
      namespace: $GATEWAY_NAMESPACE
    hostnames:
    - "$HOSTNAME"
    rules:
    - matches:
      - path:
          type: PathPrefix
          value: /
      backendRefs:
      - name: $SERVICE_NAME
        port: $SERVICE_PORT
EOF
}

# configureGatewayRoute: main function to configure HTTPRoute via extraDeploy
# Arguments: values_file, gateway_class, hostname, service_name, service_port, namespace
configureGatewayRoute() {
  local VALUES_FILE=$1
  local GATEWAY_CLASS=$2
  local HOSTNAME=$3
  local SERVICE_NAME=$4
  local SERVICE_PORT=$5
  local NAMESPACE=$6

  debug "configureGatewayRoute: class=$GATEWAY_CLASS, host=$HOSTNAME, service=$SERVICE_NAME:$SERVICE_PORT"

  # Check if gateway class exists
  if ! isGatewayClassAvailable "$GATEWAY_CLASS"; then
    boldWarn "GatewayClass '$GATEWAY_CLASS' not found. Install a gateway controller first (e.g., 'vkdr nginx-gw install')"
    return 1
  fi

  # Find gateway for this class
  local GATEWAY_INFO=$(getGatewayByClass "$GATEWAY_CLASS")
  if [ -z "$GATEWAY_INFO" ]; then
    boldWarn "No Gateway found for class '$GATEWAY_CLASS'. Create a gateway first."
    return 1
  fi

  local GATEWAY_NAME=$(echo "$GATEWAY_INFO" | cut -d: -f1)
  local GATEWAY_NAMESPACE=$(echo "$GATEWAY_INFO" | cut -d: -f2)
  debug "configureGatewayRoute: using gateway '$GATEWAY_NAME' in namespace '$GATEWAY_NAMESPACE'"

  # Disable ingress
  $VKDR_YQ -i ".ingress.enabled = false" "$VALUES_FILE"

  # Generate HTTPRoute and add to extraDeploy
  local HTTPROUTE_YAML=$(generateHTTPRouteYAML "$SERVICE_NAME" "$NAMESPACE" "$GATEWAY_NAME" "$GATEWAY_NAMESPACE" "$HOSTNAME" "$SERVICE_NAME" "$SERVICE_PORT")

  # Write HTTPRoute to temp file and merge into extraDeploy
  echo "$HTTPROUTE_YAML" > /tmp/httproute-extradeploy.yaml
  $VKDR_YQ -i ".extraDeploy = load(\"/tmp/httproute-extradeploy.yaml\")" "$VALUES_FILE"

  boldNotice "Configured HTTPRoute for gateway '$GATEWAY_NAME' (class: $GATEWAY_CLASS)"
}
