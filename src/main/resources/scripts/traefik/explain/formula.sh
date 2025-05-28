#!/usr/bin/env bash

#source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"

runFormula() {
  explainTraefik
}

explainTraefik() {
  info "Explain Traefik Ingress Controller"
  info "$VKDR_GLOW -p $(dirname "$0")/../../.docs/TRAEFIK.md"
  $VKDR_GLOW -p "$(dirname "$0")/../../.docs/TRAEFIK.md"
}

runFormula
