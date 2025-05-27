#!/usr/bin/env bash

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

startInfos() {
  boldInfo "Traefik Remove"
  bold "=============================="
  bold "=============================="
}

removeTraefik() {
  debug "removeTraefik: uninstalling traefik"
  $VKDR_HELM uninstall traefik
}

runFormula() {
  startInfos
  removeTraefik
}

runFormula
