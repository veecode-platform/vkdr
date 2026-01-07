#!/usr/bin/env bash

VKDR_ENV_POSTGRES_ADMIN_PASSWORD=$1
VKDR_ENV_POSTGRES_WAIT_FOR=$2

# V2 paths: relative to formulas/postgres/install/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

POSTGRES_NAMESPACE=vkdr
POSTGRES_CLUSTER_NAME=vkdr-pg-cluster
CNPG_OPERATOR_YAML="$SHARED_DIR/operators/cnpg-1.27.0.yaml"

startInfos() {
  boldInfo "Postgres Install (CloudNative-PG)"
  bold "=============================="
  boldNotice "Cluster name: $POSTGRES_CLUSTER_NAME"
  boldNotice "Admin password: $VKDR_ENV_POSTGRES_ADMIN_PASSWORD"
  boldNotice "Wait for it: $VKDR_ENV_POSTGRES_WAIT_FOR"
  bold "=============================="
}

runFormula() {
  startInfos
  createNamespace
  install
  postInstall
}


install() {
  # Install CloudNative-PG operator if not already installed
  if ! kubectl get deployment cnpg-controller-manager -n cnpg-system &>/dev/null; then
    debug "install: deploying CloudNative-PG operator"
    kubectl apply --server-side -f "$CNPG_OPERATOR_YAML"
    info "Waiting for CloudNative-PG operator to be ready..."
    kubectl wait --for=condition=Available --timeout=300s \
      deployment/cnpg-controller-manager -n cnpg-system
  else
    info "CloudNative-PG operator already installed, skipping..."
  fi

  # Create secret for postgres superuser ("app") password if it doesn't exist
  if ! kubectl get secret "${POSTGRES_CLUSTER_NAME}-superuser" -n "$POSTGRES_NAMESPACE" &>/dev/null; then
    debug "install: creating postgres superuser secret"
    kubectl create secret generic "${POSTGRES_CLUSTER_NAME}-superuser" \
      -n "$POSTGRES_NAMESPACE" \
      --from-literal=username="app" \
      --from-literal=password="$VKDR_ENV_POSTGRES_ADMIN_PASSWORD"
  else
    info "Postgres superuser secret already exists, skipping..."
  fi

  # Create PostgreSQL Cluster
  debug "install: creating PostgreSQL cluster"
  createCluster

  if [ "true" = "$VKDR_ENV_POSTGRES_WAIT_FOR" ]; then
    waitForCluster
  fi
}

waitForCluster() {
  info "Waiting for PostgreSQL cluster to be ready..."
  local retries=0
  local max_retries=60

  while [ "$retries" -lt "$max_retries" ]; do
    local ready_instances=$(kubectl get cluster "$POSTGRES_CLUSTER_NAME" -n "$POSTGRES_NAMESPACE" -o jsonpath='{.status.readyInstances}' 2>/dev/null || echo "0")
    local instances=$(kubectl get cluster "$POSTGRES_CLUSTER_NAME" -n "$POSTGRES_NAMESPACE" -o jsonpath='{.spec.instances}' 2>/dev/null || echo "0")

    if [ "$ready_instances" = "$instances" ] && [ "$ready_instances" != "0" ]; then
      info "PostgreSQL cluster is ready! ($ready_instances/$instances instances)"
      return 0
    fi

    debug "Waiting for cluster... ($ready_instances/$instances instances ready)"
    sleep 5
    retries=$((retries + 1))
  done

  error "Timeout waiting for PostgreSQL cluster to be ready"
  exit 1
}

postInstall() {
  info "Postgres install finished!"
}

createNamespace() {
  echo "
apiVersion: v1
kind: Namespace
metadata:
  name: $POSTGRES_NAMESPACE
" | kubectl apply -f -
}

createCluster() {
  echo "
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: $POSTGRES_CLUSTER_NAME
  namespace: $POSTGRES_NAMESPACE
spec:
  instances: 1

  postgresql:
    parameters:
      max_connections: \"50\"
      shared_buffers: \"64MB\"
      work_mem: \"4MB\"
      maintenance_work_mem: \"32MB\"
      effective_cache_size: \"128MB\"

  resources:
    requests:
      memory: \"256Mi\"
      cpu: \"100m\"
    limits:
      memory: \"512Mi\"
      cpu: \"500m\"

  bootstrap:
    initdb:
      secret:
        name: ${POSTGRES_CLUSTER_NAME}-superuser

  storage:
    size: 512Mi
    storageClass: local-path

  monitoring:
    enablePodMonitor: false
" | kubectl apply -f -
}

runFormula
