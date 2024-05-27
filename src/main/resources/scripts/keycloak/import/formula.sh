#!/usr/bin/env bash

VKDR_ENV_KEYCLOAK_IMPORT_FILE=$1

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

KEYCLOAK_NAMESPACE=vkdr

startInfos() {
  boldInfo "Keycloak Import Realm"
  bold "=============================="
  boldNotice "File: $VKDR_ENV_KEYCLOAK_IMPORT_FILE"
  bold "=============================="
}

runFormula() {
  startInfos
  import
  postImport
}

import() {
  debug "TODO: Keycloak import realm"
}

postImport() {
  info "Keycloak import realm finished!"
}

runFormula
