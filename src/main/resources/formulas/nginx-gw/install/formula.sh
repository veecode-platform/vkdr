#!/usr/bin/env bash

VKDR_ENV_NGINX_GW_NODE_PORTS=$1

# V2 paths: relative to formulas/nginx-gw/install/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

# NGINX Gateway Fabric version
NGF_VERSION="2.3.0"

startInfos() {
  boldInfo "NGINX Gateway Fabric Install"
  bold "=============================="
  boldNotice "Node ports: $VKDR_ENV_NGINX_GW_NODE_PORTS"
  bold "=============================="
}

installGatewayAPICRDs() {
  debug "installGatewayAPICRDs: installing Gateway API CRDs"
  $VKDR_KUBECTL kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v$NGF_VERSION" | $VKDR_KUBECTL apply -f -
}

isControlPlaneInstalled() {
  $VKDR_HELM list -n nginx-gateway -q 2>/dev/null | grep -q "nginx-gateway"
}

installControlPlane() {
  debug "installControlPlane: installing NGINX Gateway Fabric control plane"

  installGatewayAPICRDs

  $VKDR_HELM upgrade --install nginx-gateway oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
    --version "$NGF_VERSION" \
    --create-namespace \
    --namespace nginx-gateway \
    --set "nginxGateway.gatewayClassName=nginx"
}

createDefaultGateway() {
  debug "createDefaultGateway: creating default Gateway resource"
  if [ -z "$VKDR_ENV_NGINX_GW_NODE_PORTS" ]; then
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
  name: nginx
  namespace: nginx-gateway
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
EOF
}

createGatewayNP() {
  if [ "*" = "$VKDR_ENV_NGINX_GW_NODE_PORTS" ]; then
    NGW_PORT_1=30000
    NGW_PORT_2=30001
  else
    IFS=',' read -r NGW_PORT_1 NGW_PORT_2 <<< "$VKDR_ENV_NGINX_GW_NODE_PORTS"
  fi
  debug "createGatewayNP: creating Gateway with NodePort service ($NGW_PORT_1, $NGW_PORT_2)"
  $VKDR_KUBECTL apply -f - <<EOF
apiVersion: gateway.nginx.org/v1alpha2
kind: NginxProxy
metadata:
  name: nginx-proxy-config
  namespace: nginx-gateway
spec:
  kubernetes:
    service:
      type: NodePort
      nodePorts:
      - port: $NGW_PORT_1
        listenerPort: 80
      - port: $NGW_PORT_2
        listenerPort: 443
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: nginx
  namespace: nginx-gateway
spec:
  gatewayClassName: nginx
  infrastructure:
    parametersRef:
      group: gateway.nginx.org
      kind: NginxProxy
      name: nginx-proxy-config
  listeners:
  - name: http
    port: 80
    protocol: HTTP
EOF
}

runFormula() {
  startInfos
  if isControlPlaneInstalled; then
    boldNotice "Control plane already installed, creating Gateway only"
  else
    installControlPlane
  fi
  createDefaultGateway
}

runFormula
