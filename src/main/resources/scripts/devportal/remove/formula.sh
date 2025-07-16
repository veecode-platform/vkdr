#!/usr/bin/env bash

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

VKDR_NAMESPACE=platform

startInfos() {
  boldInfo "DevPortal Remove"
  bold "=============================="
}

runFormula() {
  startInfos
  remove
}

remove() {
  helm delete veecode-devportal -n $VKDR_NAMESPACE
}

runFormula
