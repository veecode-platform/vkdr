#!/usr/bin/env bash

VKDR_ENV_KONG_GW_NODE_PORTS=$1

# V2 paths: relative to formulas/kong-gw/install/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

# Kong Gateway Operator version
KGO_VERSION="1.0.2"

startInfos() {
  boldInfo "Kong Gateway Operator Install"
  bold "=============================="
  boldNotice "Node ports: $VKDR_ENV_KONG_GW_NODE_PORTS"
  bold "=============================="
}

installGatewayAPICRDs() {
  debug "installGatewayAPICRDs: installing Gateway API CRDs"
  # Kong Gateway Operator requires Gateway API CRDs
  $VKDR_KUBECTL apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
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

  installGatewayAPICRDs
  createSelfSignedCert

  $VKDR_HELM repo add kong https://charts.konghq.com 2>/dev/null || true
  $VKDR_HELM repo update kong

  $VKDR_HELM upgrade --install kong-operator kong/kong-operator \
    --version "$KGO_VERSION" \
    --create-namespace \
    --namespace kong-system
}

createGatewayClass() {
  debug "createGatewayClass: creating GatewayClass for Kong"
  $VKDR_KUBECTL apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kong
spec:
  controllerName: konghq.com/gateway-operator
EOF
}

createDefaultGateway() {
  debug "createDefaultGateway: creating default Gateway resource"
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
    KGW_PORT_1=30080
    KGW_PORT_2=30443
  else
    IFS=',' read -r KGW_PORT_1 KGW_PORT_2 <<< "$VKDR_ENV_KONG_GW_NODE_PORTS"
  fi
  debug "createGatewayNP: creating Gateway with NodePort service ($KGW_PORT_1, $KGW_PORT_2)"

  # Create GatewayConfiguration for NodePort
  $VKDR_KUBECTL apply -f - <<EOF
apiVersion: gateway-operator.konghq.com/v1beta1
kind: GatewayConfiguration
metadata:
  name: kong-config
  namespace: kong-system
spec:
  dataPlaneOptions:
    deployment:
      replicas: 1
    network:
      services:
        ingress:
          type: NodePort
          annotations:
            konghq.com/nodeport-http: "$KGW_PORT_1"
            konghq.com/nodeport-https: "$KGW_PORT_2"
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong
  namespace: kong-system
  annotations:
    konghq.com/gateway-configuration: kong-config
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
  createGatewayClass
  createDefaultGateway
}

runFormula
