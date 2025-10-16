#!/usr/bin/env bash

VKDR_ENV_POSTGRES_DELETE_STORAGE=$1

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

POSTGRES_NAMESPACE=vkdr
POSTGRES_CLUSTER_NAME=vkdr-pg-cluster

startInfos() {
  boldInfo "Postgres Remove (CloudNative-PG)"
  bold "=============================="
  boldNotice "Cluster name: $POSTGRES_CLUSTER_NAME"
  boldNotice "Delete storage/secret: $VKDR_ENV_POSTGRES_DELETE_STORAGE"
  bold "=============================="
  infoYellow "Note: PVCs are retained by default and will be reused if postgres is reinstalled."
}

runFormula() {
  startInfos
  remove
}

remove() {
  boldInfo "Removing PostgreSQL cluster..."
  kubectl delete cluster "$POSTGRES_CLUSTER_NAME" -n "$POSTGRES_NAMESPACE"
  
  if [ "$VKDR_ENV_POSTGRES_DELETE_STORAGE" = "true" ]; then
    boldInfo "Deleting PostgreSQL PVCs..."
    kubectl delete pvc -n "$POSTGRES_NAMESPACE" -l "cnpg.io/cluster=$POSTGRES_CLUSTER_NAME"
    boldInfo "Deleting PostgreSQL superuser secret..."
    kubectl delete secret "${POSTGRES_CLUSTER_NAME}-superuser" -n "$POSTGRES_NAMESPACE" --ignore-not-found
  fi
}

runFormula
