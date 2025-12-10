#!/usr/bin/env bash

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

OPENLDAP_NAMESPACE=vkdr
OPENLDAP_RELEASE_NAME=openldap

startInfos() {
  boldInfo "OpenLDAP Remove"
  bold "=============================="
}

runFormula() {
  startInfos
  remove
  postRemove
}

remove() {
  debug "OpenLDAP remove"
  $VKDR_HELM delete $OPENLDAP_RELEASE_NAME --namespace $OPENLDAP_NAMESPACE 2>/dev/null || true
}

postRemove() {
  boldInfo "OpenLDAP removed!"
}

runFormula
