#!/usr/bin/env bash

#VKDR_ENV_NGINX_DOMAIN=localhost
#VKDR_ENV_NGINX_SECURE=false
VKDR_ENV_NGINX_DEFAULT=$1

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

startInfos() {
  boldInfo "Nginx Install"
  bold "=============================="
  #boldNotice "Domain: $VKDR_ENV_NGINX_DOMAIN"
  boldNotice "Default ingress: $VKDR_ENV_NGINX_DEFAULT"
  bold "=============================="
}

installNginx() {
  debug "installNginx: add/update helm repo"
  $VKDR_HELM repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  $VKDR_HELM repo update
  debug "installNginx: installing nginx"
  $VKDR_HELM upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --set "controller.ingressClassResource.default=$VKDR_ENV_NGINX_DEFAULT"
}

runFormula() {
  startInfos
  installNginx
}

runFormula
