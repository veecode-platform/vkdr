#!/usr/bin/env bash

FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

CROSSPLANE_NAMESPACE=crossplane-system
PROVIDER="$1"
DO_TOKEN="$2"
AWS_CREDENTIAL_FILE="$3"

startInfos() {
  boldInfo "Crossplane Install"
  bold "=============================="
}

install() {
  local helmSetArgs=""

  case "$PROVIDER" in
    do)
      helmSetArgs="--set provider.packages={xpkg.upbound.io/crossplane-contrib/provider-upjet-digitalocean:v0.3.0}"
      ;;
    aws)
      helmSetArgs="--set provider.packages={xpkg.upbound.io/upbound/provider-aws-s3:v1.22.0}"
      ;;
  esac

  $VKDR_HELM repo add crossplane-stable https://charts.crossplane.io/stable
  $VKDR_HELM repo update crossplane-stable
  $VKDR_HELM upgrade -i crossplane crossplane-stable/crossplane \
    -n $CROSSPLANE_NAMESPACE --create-namespace $helmSetArgs

  info "Waiting for Crossplane to be ready..."
  $VKDR_KUBECTL wait --for=condition=Available --timeout=120s \
    deployment/crossplane -n $CROSSPLANE_NAMESPACE
}

waitForProvider() {
  local providerName="$1"
  local timeout=120
  local elapsed=0

  # Wait for the Provider resource to exist
  info "Waiting for provider $providerName to be created..."
  while ! $VKDR_KUBECTL get provider.pkg.crossplane.io/"$providerName" &>/dev/null; do
    if [ $elapsed -ge $timeout ]; then
      error "Timed out waiting for provider $providerName to be created"
      return 1
    fi
    sleep 5
    elapsed=$((elapsed + 5))
  done

  # Wait for the Provider to become healthy
  $VKDR_KUBECTL wait --for=condition=Healthy provider.pkg.crossplane.io/"$providerName" \
    --timeout=$((timeout - elapsed))s
}

installProvider() {
  case "$PROVIDER" in
    do)
      installProviderDO
      ;;
    aws)
      installProviderAWS
      ;;
  esac
}

installProviderDO() {
  if [ -z "$DO_TOKEN" ]; then
    error "DigitalOcean provider requires --do-token"
    return 1
  fi

  info "Waiting for DigitalOcean provider to become ready..."
  waitForProvider "crossplane-contrib-provider-upjet-digitalocean"

  info "Creating DigitalOcean credentials secret..."
  $VKDR_KUBECTL delete secret provider-do-secret -n $CROSSPLANE_NAMESPACE --ignore-not-found
  $VKDR_KUBECTL create secret generic provider-do-secret \
    -n $CROSSPLANE_NAMESPACE \
    --from-literal=credentials="{\"token\":\"$DO_TOKEN\"}"

  info "Applying DigitalOcean ProviderConfig..."
  $VKDR_KUBECTL apply -f - <<EOF
apiVersion: digitalocean.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: $CROSSPLANE_NAMESPACE
      name: provider-do-secret
      key: credentials
EOF
}

installProviderAWS() {
  if [ -z "$AWS_CREDENTIAL_FILE" ]; then
    error "AWS provider requires --aws-credential-file"
    return 1
  fi

  if [ ! -f "$AWS_CREDENTIAL_FILE" ]; then
    error "AWS credentials file not found: $AWS_CREDENTIAL_FILE"
    return 1
  fi

  info "Waiting for AWS provider to become ready..."
  waitForProvider "upbound-provider-aws-s3"

  info "Creating AWS credentials secret..."
  $VKDR_KUBECTL delete secret provider-aws-secret -n $CROSSPLANE_NAMESPACE --ignore-not-found
  $VKDR_KUBECTL create secret generic provider-aws-secret \
    -n $CROSSPLANE_NAMESPACE \
    --from-file=credentials="$AWS_CREDENTIAL_FILE"

  info "Applying AWS ProviderConfig..."
  $VKDR_KUBECTL apply -f - <<EOF
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: $CROSSPLANE_NAMESPACE
      name: provider-aws-secret
      key: credentials
EOF
}

postInstall() {
  info "Crossplane install finished!"
}

runFormula() {
  startInfos
  install
  if [ -n "$PROVIDER" ] && [ "$PROVIDER" != "none" ]; then
    installProvider
  fi
  postInstall
}

runFormula
