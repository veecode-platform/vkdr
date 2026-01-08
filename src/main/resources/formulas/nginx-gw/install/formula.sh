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

installNginxGatewayFabric() {
  debug "installNginxGatewayFabric: installing NGINX Gateway Fabric"

  installGatewayAPICRDs

  if [ -z "$VKDR_ENV_NGINX_GW_NODE_PORTS" ]; then
    installNginxGwLB
  else
    installNginxGwNP
  fi
}

installNginxGwLB() {
  debug "installNginxGwLB: installing nginx gateway fabric as LoadBalancer"
  $VKDR_HELM upgrade --install nginx-gateway oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
    --version "$NGF_VERSION" \
    --create-namespace \
    --namespace nginx-gateway \
    --set "nginxGateway.gatewayClassName=nginx"
}

installNginxGwNP() {
  debug "installNginxGwNP: installing nginx gateway fabric as NodePort"
  if [ "*" = "$VKDR_ENV_NGINX_GW_NODE_PORTS" ]; then
    NGW_PORT_1=30000
    NGW_PORT_2=30001
  else
    IFS=',' read -r NGW_PORT_1 NGW_PORT_2 <<< "$VKDR_ENV_NGINX_GW_NODE_PORTS"
  fi
  debug "installNginxGwNP: using nodePorts $NGW_PORT_1 and $NGW_PORT_2"
  $VKDR_HELM upgrade --install nginx-gateway oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
    --version "$NGF_VERSION" \
    --create-namespace \
    --namespace nginx-gateway \
    --set "nginxGateway.gatewayClassName=nginx" \
    --set "service.type=NodePort" \
    --set "service.ports[0].port=80" \
    --set "service.ports[0].targetPort=80" \
    --set "service.ports[0].protocol=TCP" \
    --set "service.ports[0].name=http" \
    --set "service.ports[0].nodePort=$NGW_PORT_1" \
    --set "service.ports[1].port=443" \
    --set "service.ports[1].targetPort=443" \
    --set "service.ports[1].protocol=TCP" \
    --set "service.ports[1].name=https" \
    --set "service.ports[1].nodePort=$NGW_PORT_2"
}

createDefaultGateway() {
  debug "createDefaultGateway: creating default Gateway resource"
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

runFormula() {
  startInfos
  installNginxGatewayFabric
  createDefaultGateway
}

runFormula
