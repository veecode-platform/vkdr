#!/usr/bin/env bash

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

MINIO_NAMESPACE=vkdr

startInfos() {
  boldInfo "Minio Remove"
  bold "=============================="
}

runFormula() {
  startInfos
  removeMinio
}

removeMinio() {
  $VKDR_HELM delete minio -n $MINIO_NAMESPACE
}

runFormula
