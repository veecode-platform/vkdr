#!/usr/bin/env bash

VKDR_ENV_DEVPORTAL_DOMAIN=$1
#VKDR_ENV_NGINX_SECURE=false

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

startInfos() {
  boldInfo "Nginx Install"
  bold "=============================="
  boldNotice "Domain: $VKDR_ENV_DEVPORTAL_DOMAIN"
  #boldNotice "Secure: $VKDR_ENV_NGINX_SECURE"
  bold "=============================="
}

installDevPortal() {
  debug "installDevPortal: add/update helm repo"
  helm repo add veecode-platform https://veecode-platform.github.io/public-charts/
  helm repo update
  debug "installDevPortal: installing devportal (TODO)"
  #helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx
}

runFormula() {
  startInfos
  installDevPortal
}

runFormula
