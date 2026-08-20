#!/usr/bin/env bash

VKDR_ENV_KONG_GW_NODE_PORTS=$1
VKDR_ENV_KONG_GW_IMAGE_NAME=$2
VKDR_ENV_KONG_GW_IMAGE_TAG=$3
VKDR_ENV_KONG_GW_PROFILE=$4
VKDR_ENV_KONG_GW_DEFAULT_IC=$5

# V2 paths: relative to formulas/kong-gw/install/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

# Kong Gateway Operator chart and image
KGO_CHART_VERSION="1.3.1"
KGO_IMAGE_TAG="2.2.3"
# Gateway API bundle the chart ships at this version - installed from the shared
# copy instead, so nginx-gw and kong-gw agree on one pinned bundle
GWAPI_CRDS_YAML="$SHARED_DIR/operators/gateway-api/gateway-api-standard-1.5.1.yaml"
# Kong data plane image. 3.14 is the last release whose enterprise image keeps
# working unlicensed, so it is the default; "-distroless" tags behave the same.
KONG_GW_DEFAULT_IMAGE_NAME="kong/kong-gateway"
KONG_GW_DEFAULT_IMAGE_TAG="3.14"
KONG_GW_CONFIG_NAME="kong-config"
# Ingress support: the control plane only reconciles Ingress objects when an
# ingress class is set, and KIC claims the ones whose ingressClassName matches.
KONG_GW_INGRESS_CLASS="kong"
KONG_GW_INGRESS_CONTROLLER="ingress-controllers.konghq.com/kong"

# Image profiles: shortcuts for the image name/tag pairs we support. Keep in sync
# with the table in _meta/docs.md. "default" sets nothing, so the formula default
# applies. Kong Gateway 3.15 needs a license to keep serving traffic.
resolveProfile() {
  PROFILE_IMAGE_NAME=""
  PROFILE_IMAGE_TAG=""
  case "$1" in
    kong)
      PROFILE_IMAGE_NAME="kong/kong-gateway"; PROFILE_IMAGE_TAG="3.15.0.4" ;;
    kong-distroless)
      PROFILE_IMAGE_NAME="kong/kong-gateway"; PROFILE_IMAGE_TAG="3.15-distroless" ;;
    oss)
      PROFILE_IMAGE_NAME="kong"; PROFILE_IMAGE_TAG="3.9.3" ;;
    apip)
      PROFILE_IMAGE_NAME="veecode/kong"; PROFILE_IMAGE_TAG="3.10.0-veecode.10" ;;
    apip-distroless)
      PROFILE_IMAGE_NAME="veecode/kong"; PROFILE_IMAGE_TAG="3.10.0-veecode.10-distroless" ;;
    default|"")
      ;;
    *)
      boldWarn "Unknown profile '$1', falling back to the default image" ;;
  esac
}

# Precedence: explicit --image/--tag, then --profile, then the formula default
resolveProfile "$VKDR_ENV_KONG_GW_PROFILE"
: "${VKDR_ENV_KONG_GW_IMAGE_NAME:=${PROFILE_IMAGE_NAME:-$KONG_GW_DEFAULT_IMAGE_NAME}}"
: "${VKDR_ENV_KONG_GW_IMAGE_TAG:=${PROFILE_IMAGE_TAG:-$KONG_GW_DEFAULT_IMAGE_TAG}}"
KONG_GW_IMAGE="$VKDR_ENV_KONG_GW_IMAGE_NAME:$VKDR_ENV_KONG_GW_IMAGE_TAG"

startInfos() {
  boldInfo "Kong Gateway Operator Install"
  bold "=============================="
  if [ -n "$VKDR_ENV_KONG_GW_PROFILE" ]; then
    boldNotice "Profile: $VKDR_ENV_KONG_GW_PROFILE"
  fi
  boldNotice "Data plane image: $KONG_GW_IMAGE"
  boldNotice "Ingress class: $KONG_GW_INGRESS_CLASS"
  if [ "true" = "$VKDR_ENV_KONG_GW_DEFAULT_IC" ]; then
    boldNotice "Default ingress controller: yes"
  fi
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

installGatewayAPICRDs() {
  debug "installGatewayAPICRDs: installing Gateway API CRDs"
  $VKDR_KUBECTL apply -f "$GWAPI_CRDS_YAML"
}

installOperator() {
  debug "installOperator: installing Kong Gateway Operator"

  createSelfSignedCert
  installGatewayAPICRDs

  # Kong CRDs come from the chart's ko-crds subchart (templated, so helm upgrades
  # them); Gateway API CRDs are installed above from the pinned shared copy.
  $VKDR_HELM upgrade --install kong-operator kong-operator \
    --repo https://charts.konghq.com \
    --version "$KGO_CHART_VERSION" \
    --create-namespace \
    --namespace kong-system \
    --set gwapi-standard-crds.enabled=false \
    --set image.tag="$KGO_IMAGE_TAG"
}

# The IngressClass object is what makes "ingressClassName: kong" resolve, and
# carries the is-default-class annotation. The value is always written so that
# re-running install without --default-ic actually gives the default back up.
createIngressClass() {
  debug "createIngressClass: creating IngressClass $KONG_GW_INGRESS_CLASS (default=$VKDR_ENV_KONG_GW_DEFAULT_IC)"
  local is_default="false"
  [ "true" = "$VKDR_ENV_KONG_GW_DEFAULT_IC" ] && is_default="true"
  $VKDR_KUBECTL apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: $KONG_GW_INGRESS_CLASS
  annotations:
    ingressclass.kubernetes.io/is-default-class: "$is_default"
spec:
  controller: $KONG_GW_INGRESS_CONTROLLER
EOF
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
  applyGatewayResources ""
}

createGatewayNP() {
  if [ "*" = "$VKDR_ENV_KONG_GW_NODE_PORTS" ]; then
    KGW_PORT_HTTP=30000
    KGW_PORT_HTTPS=30001
  else
    IFS=',' read -r KGW_PORT_HTTP KGW_PORT_HTTPS <<< "$VKDR_ENV_KONG_GW_NODE_PORTS"
  fi
  debug "createGatewayNP: creating Gateway with NodePort service ($KGW_PORT_HTTP, $KGW_PORT_HTTPS)"

  applyGatewayResources "nodeport"

  # Wait for the dataplane service to be created by the operator
  boldNotice "Waiting for dataplane service..."
  waitForDataplaneService

  # Patch the service to use specific NodePort values
  patchServiceNodePorts "$KGW_PORT_HTTP" "$KGW_PORT_HTTPS"
}

# Renders the GatewayConfiguration network block. NodePort mode is the only case
# where the ingress service type differs from the operator default.
gatewayNetworkBlock() {
  if [ "nodeport" = "$1" ]; then
    cat <<EOF
    network:
      services:
        ingress:
          type: NodePort
          externalTrafficPolicy: Local
EOF
  fi
}

# The GatewayConfiguration is always created: it is what pins the data plane
# image, so LoadBalancer and NodePort modes only differ in the network block.
# See https://developer.konghq.com/operator/dataplanes/how-to/set-dataplane-image/
applyGatewayResources() {
  local mode="$1"
  $VKDR_KUBECTL apply -f - <<EOF
apiVersion: gateway-operator.konghq.com/v2beta1
kind: GatewayConfiguration
metadata:
  name: $KONG_GW_CONFIG_NAME
  namespace: kong-system
spec:
  controlPlaneOptions:
    ingressClass: $KONG_GW_INGRESS_CLASS
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
          - name: proxy
            image: $KONG_GW_IMAGE
$(gatewayNetworkBlock "$mode")
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
    name: $KONG_GW_CONFIG_NAME
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
  createIngressClass
}

runFormula
