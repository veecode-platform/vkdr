#!/usr/bin/env bash

VKDR_ENV_KONG_GW_NODE_PORTS=$1

# V2 paths: relative to formulas/kong-gw/install/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

# Kong Gateway Operator image tag
KGO_IMAGE_TAG="2.0.6"

startInfos() {
  boldInfo "Kong Gateway Operator Install"
  bold "=============================="
  if [ -n "$VKDR_ENV_KONG_GW_NODE_PORTS" ]; then
    boldNotice "Node ports: $VKDR_ENV_KONG_GW_NODE_PORTS"
  fi
  bold "=============================="
}

isOperatorInstalled() {
  $VKDR_HELM list -n kong-system -q 2>/dev/null | grep -q "kong-operator"
}

isTlsSecretExists() {
  $VKDR_KUBECTL get secret kong-gateway-tls -n kong-system &>/dev/null
}

createSelfSignedCert() {
  debug "createSelfSignedCert: generating self-signed certificate"

  if isTlsSecretExists; then
    boldNotice "TLS secret already exists, skipping certificate generation"
    return
  fi

  local TEMP_DIR=$(mktemp -d)

  # Generate self-signed certificate with SANs for localhost and localdomain
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$TEMP_DIR/tls.key" \
    -out "$TEMP_DIR/tls.crt" \
    -subj "/CN=kong-gateway/O=VKDR Fake Authority/OU=Trust Me Bro Security/L=La Garantia Soy Yo City/ST=Kubernetes" \
    -addext "subjectAltName=DNS:localhost,DNS:*.localhost,DNS:localdomain,DNS:*.localdomain" \
    2>/dev/null

  # Create namespace if it doesn't exist
  $VKDR_KUBECTL create namespace kong-system --dry-run=client -o yaml | $VKDR_KUBECTL apply -f -

  # Create TLS secret
  $VKDR_KUBECTL create secret tls kong-gateway-tls \
    --cert="$TEMP_DIR/tls.crt" \
    --key="$TEMP_DIR/tls.key" \
    -n kong-system \
    --dry-run=client -o yaml | $VKDR_KUBECTL apply -f -

  # Cleanup temp files
  rm -rf "$TEMP_DIR"

  boldNotice "Self-signed TLS certificate created"
}

installOperator() {
  debug "installOperator: installing Kong Gateway Operator"

  createSelfSignedCert

  $VKDR_HELM repo add kong https://charts.konghq.com 2>/dev/null || true
  $VKDR_HELM repo update kong

  # Helm chart includes all CRDs (Gateway API + Kong CRDs)
  $VKDR_HELM upgrade --install kong-operator kong/kong-operator \
    --create-namespace \
    --namespace kong-system \
    --set image.tag="$KGO_IMAGE_TAG"
}

createGateway() {
  debug "createGateway: creating Gateway resource"
  if [ -z "$VKDR_ENV_KONG_GW_NODE_PORTS" ]; then
    createGatewayLB
  else
    createGatewayNP
  fi
}

createGatewayLB() {
  debug "createGatewayLB: creating Gateway with LoadBalancer service"
  $VKDR_KUBECTL apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kong
spec:
  controllerName: konghq.com/gateway-operator
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong
  namespace: kong-system
spec:
  gatewayClassName: kong
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
  - name: https
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - kind: Secret
        name: kong-gateway-tls
    allowedRoutes:
      namespaces:
        from: All
EOF
}

createGatewayNP() {
  if [ "*" = "$VKDR_ENV_KONG_GW_NODE_PORTS" ]; then
    KGW_PORT_HTTP=30000
    KGW_PORT_HTTPS=30001
  else
    IFS=',' read -r KGW_PORT_HTTP KGW_PORT_HTTPS <<< "$VKDR_ENV_KONG_GW_NODE_PORTS"
  fi
  debug "createGatewayNP: creating Gateway with NodePort service ($KGW_PORT_HTTP, $KGW_PORT_HTTPS)"

  # Create GatewayConfiguration with NodePort service type
  $VKDR_KUBECTL apply -f - <<EOF
apiVersion: gateway-operator.konghq.com/v2beta1
kind: GatewayConfiguration
metadata:
  name: kong-nodeport-config
  namespace: kong-system
spec:
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
          - name: proxy
            image: kong:3.9.1
    network:
      services:
        ingress:
          type: NodePort
          externalTrafficPolicy: Local
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kong
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: kong-nodeport-config
    namespace: kong-system
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong
  namespace: kong-system
spec:
  gatewayClassName: kong
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
  - name: https
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - kind: Secret
        name: kong-gateway-tls
    allowedRoutes:
      namespaces:
        from: All
EOF

  # Wait for the dataplane service to be created by the operator
  boldNotice "Waiting for dataplane service..."
  waitForDataplaneService

  # Patch the service to use specific NodePort values
  patchServiceNodePorts "$KGW_PORT_HTTP" "$KGW_PORT_HTTPS"
}

waitForDataplaneService() {
  debug "waitForDataplaneService: waiting for dataplane ingress service"
  local max_wait=120
  local waited=0
  while [ $waited -lt $max_wait ]; do
    local svc_name=$($VKDR_KUBECTL get svc -n kong-system -o name 2>/dev/null | grep "dataplane-ingress" | head -1)
    if [ -n "$svc_name" ]; then
      debug "waitForDataplaneService: found service $svc_name"
      return 0
    fi
    debug "waitForDataplaneService: waiting... ($waited/$max_wait)"
    sleep 3
    waited=$((waited + 3))
  done
  boldWarn "Timeout waiting for dataplane service"
  return 1
}

patchServiceNodePorts() {
  local http_port=$1
  local https_port=$2
  debug "patchServiceNodePorts: patching service with NodePorts $http_port, $https_port"

  # Find the dataplane ingress service
  local svc_name=$($VKDR_KUBECTL get svc -n kong-system -o name 2>/dev/null | grep "dataplane-ingress" | head -1)
  if [ -z "$svc_name" ]; then
    boldWarn "Could not find dataplane ingress service to patch"
    return 1
  fi

  # Patch the NodePort values
  $VKDR_KUBECTL patch $svc_name -n kong-system --type='json' -p="[
    {\"op\": \"replace\", \"path\": \"/spec/ports/0/nodePort\", \"value\": $http_port},
    {\"op\": \"replace\", \"path\": \"/spec/ports/1/nodePort\", \"value\": $https_port}
  ]"

  boldNotice "Service patched with NodePorts: http=$http_port, https=$https_port"
}

waitForOperator() {
  debug "waitForOperator: waiting for Kong Gateway Operator deployment to be ready"
  $VKDR_KUBECTL wait --for=condition=available deployment/kong-operator-kong-operator-controller-manager \
    -n kong-system --timeout=120s 2>/dev/null || true

  debug "waitForOperator: waiting for webhook endpoints to be available"
  local max_wait=60
  local waited=0
  while [ $waited -lt $max_wait ]; do
    local endpoints=$($VKDR_KUBECTL get endpoints kong-operator-kong-operator-webhook -n kong-system -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "")
    if [ -n "$endpoints" ]; then
      debug "waitForOperator: webhook endpoints ready: $endpoints"
      break
    fi
    debug "waitForOperator: waiting for webhook endpoints... ($waited/$max_wait)"
    sleep 3
    waited=$((waited + 3))
  done
}

runFormula() {
  startInfos
  if isOperatorInstalled; then
    boldNotice "Operator already installed, creating Gateway only"
  else
    installOperator
    waitForOperator
  fi
  createGateway
}

runFormula
