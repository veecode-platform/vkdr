#!/usr/bin/env bash

VKDR_ENV_OPENLDAP_DELETE_PVC=$1

# V2 paths: relative to formulas/openldap/remove/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

OPENLDAP_NAMESPACE=vkdr
OPENLDAP_RELEASE_NAME=openldap

startInfos() {
  boldInfo "OpenLDAP Remove"
  bold "=============================="
  boldNotice "Delete PVC: $VKDR_ENV_OPENLDAP_DELETE_PVC"
  bold "=============================="
}

runFormula() {
  startInfos
  remove
}

remove() {
  debug "OpenLDAP remove"
  $VKDR_HELM delete $OPENLDAP_RELEASE_NAME --namespace $OPENLDAP_NAMESPACE 2>/dev/null || true
  if [ "$VKDR_ENV_OPENLDAP_DELETE_PVC" = "true" ]; then
    deletePvc
  fi
}

deletePvc() {
  debug "Deleting PVC data-openldap-0"
  kubectl delete pvc data-openldap-0 --namespace $OPENLDAP_NAMESPACE 2>/dev/null || true
}

postRemove() {
  boldInfo "OpenLDAP removed!"
}

runFormula
