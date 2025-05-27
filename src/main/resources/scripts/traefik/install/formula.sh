#!/usr/bin/env bash

VKDR_ENV_TRAEFIK_DOMAIN=$1
VKDR_ENV_TRAEFIK_SECURE=$2
VKDR_ENV_TRAEFIK_DEFAULT=$3
VKDR_ENV_TRAEFIK_NODE_PORTS=$4

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

startInfos() {
  boldInfo "Traefik Install"
  bold "=============================="
  boldNotice "Domain: $VKDR_ENV_TRAEFIK_DOMAIN"
  boldNotice "Secure: $VKDR_ENV_TRAEFIK_SECURE"
  boldNotice "Default ingress: $VKDR_ENV_TRAEFIK_DEFAULT"
  boldNotice "Node ports: $VKDR_ENV_TRAEFIK_NODE_PORTS"
  bold "=============================="
}

installTraefik() {
  debug "installTraefik: add/update helm repo"
  $VKDR_HELM repo add traefik https://traefik.github.io/charts
  $VKDR_HELM repo update traefik
  if [ -z "$VKDR_ENV_TRAEFIK_NODE_PORTS" ]; then
    installTraefikLB
  else
    installTraefikNP
  fi
}

installTraefikLB() {
  debug "installTraefikLB: installing traefik as LoadBalancer"
  if [ "true" = "$VKDR_ENV_TRAEFIK_DEFAULT" ]; then
    debug "installTraefikLB: traefik will become the **default** ingress controller"
  else
    debug "installTraefikLB: installing traefik ingress controller"
  fi
  $VKDR_HELM upgrade --install traefik traefik/traefik \
    -f "$(dirname "$0")/../../.util/values/traefik-common.yaml" \
    --set "ingressClass.isDefaultClass=$VKDR_ENV_TRAEFIK_DEFAULT" \
    --set "ingressRoute.dashboard.matchRule=Host(\`traefik-ui.$VKDR_ENV_TRAEFIK_DOMAIN\`)"
    #--set "additionalArguments={--entrypoints.websecure.http.tls=$([ "true" = "$VKDR_ENV_TRAEFIK_SECURE" ] && echo "true" || echo "false")}"
}

installTraefikNP() {
  debug "installTraefikNP: installing traefik as NodePort"
  if [ "*" = "$VKDR_ENV_TRAEFIK_NODE_PORTS" ]; then
    TRAEFIK_PORT_1=30000
    TRAEFIK_PORT_2=30001
  else
    IFS=',' read -r TRAEFIK_PORT_1 TRAEFIK_PORT_2 <<< "$VKDR_ENV_TRAEFIK_NODE_PORTS"
  fi
  debug "installTraefikNP: using nodePorts $TRAEFIK_PORT_1 and $TRAEFIK_PORT_2"
  if [ "true" = "$VKDR_ENV_TRAEFIK_DEFAULT" ]; then
    debug "installTraefikNP: traefik will become the **default** ingress controller"
  else
    debug "installTraefikNP: installing traefik ingress controller"
  fi
  $VKDR_HELM upgrade --install traefik traefik/traefik \
    -f "$(dirname "$0")/../../.util/values/traefik-common.yaml" \
    --set "service.type=NodePort" \
    --set "ports.web.nodePort=$TRAEFIK_PORT_1" \
    --set "ports.websecure.nodePort=$TRAEFIK_PORT_2" \
    --set "ingressClass.isDefaultClass=$VKDR_ENV_TRAEFIK_DEFAULT"
}

runFormula() {
  startInfos
  installTraefik
}

runFormula
