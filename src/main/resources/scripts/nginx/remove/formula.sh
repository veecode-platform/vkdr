#!/usr/bin/env bash

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

startInfos() {
  boldInfo "Nginx Remove"
  bold "=============================="
}

runFormula() {
  startInfos
  removeKong
}

removeKong() {
  $VKDR_HELM delete ingress-nginx
}

runFormula
