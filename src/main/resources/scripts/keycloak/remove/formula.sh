#!/usr/bin/env bash

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

KEYCLOAK_NAMESPACE=keycloak

startInfos() {
  boldInfo "Keycloak Remove"
  bold "=============================="
}

runFormula() {
  startInfos
  removeKeycloak
}

removeKeycloak() {
  helm delete keycloak -n $KEYCLOAK_NAMESPACE
}

runFormula
