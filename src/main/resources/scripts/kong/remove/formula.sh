#!/usr/bin/env bash

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

KONG_NAMESPACE=kong

startInfos() {
  boldInfo "Kong Remove"
  bold "=============================="
}

runFormula() {
  startInfos
  removeKong
}

removeKong() {
  helm delete kong -n $KONG_NAMESPACE
}

runFormula
