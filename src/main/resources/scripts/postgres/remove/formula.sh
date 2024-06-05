#!/usr/bin/env bash

VKDR_ENV_POSTGRES_DELETE_STORAGE=$1

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

POSTGRES_NAMESPACE=vkdr

startInfos() {
  boldInfo "Postgres Remove"
  bold "=============================="
  boldNotice "Delete storage: $VKDR_ENV_POSTGRES_DELETE_STORAGE"
  bold "=============================="
  infoYellow "Please understand that non-deleted storage will be mounted again if postgres is reinstalled."
}

runFormula() {
  startInfos
  remove
}

remove() {
  boldInfo "Removing postgres..."
  $VKDR_HELM delete postgres -n $POSTGRES_NAMESPACE
  if [ "$VKDR_ENV_POSTGRES_DELETE_STORAGE" = "true" ]; then
    boldInfo "Deleting postgres PVC..."
    $VKDR_KUBECTL delete pvc -n $POSTGRES_NAMESPACE "data-postgres-postgresql-0"
  fi
}

runFormula
