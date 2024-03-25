#!/usr/bin/env bash

#VKDR_ENV_NGINX_DOMAIN=localhost
#VKDR_ENV_NGINX_SECURE=false

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

startInfos() {
  boldInfo "Nginx Install"
  bold "=============================="
  #boldNotice "Domain: $VKDR_ENV_NGINX_DOMAIN"
  #boldNotice "Secure: $VKDR_ENV_NGINX_SECURE"
  #bold "=============================="
}

installNginx() {
  debug "installNginx: add/update helm repo"
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm repo update
  debug "installNginx: installing nginx"
  helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx
}

runFormula() {
  startInfos
  installNginx
}

runFormula
