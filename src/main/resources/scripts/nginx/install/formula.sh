#!/usr/bin/env bash

#VKDR_ENV_NGINX_DOMAIN=localhost
#VKDR_ENV_NGINX_SECURE=false
VKDR_ENV_NGINX_DEFAULT=$1
VKDR_ENV_NGINX_NODE_PORTS=$2

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

startInfos() {
  boldInfo "Nginx Install"
  bold "=============================="
  #boldNotice "Domain: $VKDR_ENV_NGINX_DOMAIN"
  boldNotice "Default ingress: $VKDR_ENV_NGINX_DEFAULT"
  boldNotice "Node ports: $VKDR_ENV_NGINX_NODE_PORTS"
  bold "=============================="
}


installNginx() {
  debug "installNginx: add/update helm repo"
  $VKDR_HELM repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  $VKDR_HELM repo update ingress-nginx
  if [ -z "$VKDR_ENV_NGINX_NODE_PORTS" ]; then
    installNginxLB
  else
    installNginxNP
  fi
}

installNginxLB() {
  debug "installNginxLB: installing nginx as LoadBalancer"
  if [ "true" = "$VKDR_ENV_NGINX_DEFAULT" ]; then
    debug "installNginxLB: nginx will become the **default** ingress controller"
    $VKDR_HELM upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
      --set "controller.progressDeadlineSeconds=60" \ 
      --set "controller.ingressClassResource.default=$VKDR_ENV_NGINX_DEFAULT"
  else
    debug "installNginxLB: installing nginx ingress controller"
    $VKDR_HELM upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
      --set "controller.progressDeadlineSeconds=60"
  fi
}

installNginxNP() {
  debug "installNginxNP: installing nginx as NodePort"
  if [ "*" = "$VKDR_ENV_NGINX_NODE_PORTS" ]; then
    NGINX_PORT_1=30000
    NGINX_PORT_2=30001
  else
    IFS=',' read -r NGINX_PORT_1 NGINX_PORT_2 <<< "$VKDR_ENV_NGINX_NODE_PORTS"
  fi
  debug "installNginxNP: using nodePorts $NGINX_PORT_1 and $NGINX_PORT_2"
  if [ "true" = "$VKDR_ENV_NGINX_DEFAULT" ]; then
    debug "installNginxNP: nginx will become the **default** ingress controller"
    $VKDR_HELM upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
      --set "controller.service.type=NodePort" \
      --set "controller.service.nodePorts.http=$NGINX_PORT_1" \
      --set "controller.service.nodePorts.https=$NGINX_PORT_2" \
      --set "controller.progressDeadlineSeconds=60" \ 
      --set "controller.ingressClassResource.default=$VKDR_ENV_NGINX_DEFAULT"
  else
    debug "installNginxNP: installing nginx ingress controller"
    $VKDR_HELM upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
      --set "controller.service.type=NodePort" \
      --set "controller.progressDeadlineSeconds=60" \ 
      --set "controller.service.nodePorts.http=$NGINX_PORT_1" \
      --set "controller.service.nodePorts.https=$NGINX_PORT_2"
  fi
}

runFormula() {
  startInfos
  installNginx
}

runFormula
