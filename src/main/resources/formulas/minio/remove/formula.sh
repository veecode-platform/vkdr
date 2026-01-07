#!/usr/bin/env bash

# V2 paths: relative to formulas/minio/remove/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

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
