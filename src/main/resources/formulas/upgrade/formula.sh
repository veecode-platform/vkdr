#!/usr/bin/env bash

VKDR_BIN_PATH=/usr/local/bin/vkdr
VKDR_CURRENT_VERSION="$1"
VKDR_NEW_VERSION=""
VKDR_ENV_FORCE_INSTALL=$2

# V2 paths: upgrade is one level deep (formulas/upgrade/)
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../_shared"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

KEYCLOAK_NAMESPACE=vkdr

startInfos() {
  boldInfo "VKDR Upgrade"
  bold "=============================="
  boldNotice "VKDR binary path: $VKDR_BIN_PATH"
  boldNotice "VKDR current version: $VKDR_CURRENT_VERSION"
  bold "=============================="
}

runFormula() {
  startInfos
  configure
  upgrade
  postInstall
}

configure() {
    debug "configure: detecting latest release from Github..."
    VKDR_NEW_VERSION=$(curl --silent "https://api.github.com/repos/veecode-platform/vkdr/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    debug "configure: latest release version is $VKDR_NEW_VERSION"
}

compare_versions() {
    # Strip the "v" prefix
    ver1=$(echo "$1" | sed 's/v//' | sed 's/-SNAPSHOT//')
    ver2=$(echo "$2" | sed 's/v//')

    # Split the version numbers into their components
    IFS='.' read -r -a ver1_parts <<< "$ver1"
    IFS='.' read -r -a ver2_parts <<< "$ver2"

    # Compare the components
    for i in 0 1 2; do
        if [[ ${ver1_parts[$i]} -gt ${ver2_parts[$i]} ]]; then
            debug "compare_versions: $1 is higher than $2"
            return 1
        elif [[ ${ver1_parts[$i]} -lt ${ver2_parts[$i]} ]]; then
            debug "compare_versions: $2 is higher than $1"
            return 2
        fi
    done
    debug "compare_versions: versions are equal"
    return 0
}

upgrade() {
  if [ "true" = "$VKDR_ENV_FORCE_INSTALL" ]; then
    debug "upgrade: forced upgrade, will not compare versions..."
  else
    debug "upgrade: comparing versions..."
    compare_versions "$VKDR_CURRENT_VERSION" "$VKDR_NEW_VERSION"
    result=$?
    case $result in
        0) info "Versions are equal, will not upgrade."
           return;;
        1) debug "Current version is higher than latest public release, will not upgrade"
           return;;
        2) debug "New release available: $VKDR_NEW_VERSION , upgrading..." ;;
    esac
  fi
  source "$FORMULA_DIR/get-vkdr.sh"
}

postInstall() {
  info "VKDR upgrade finished!"
}

runFormula
