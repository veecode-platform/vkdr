#!/usr/bin/env bash

addHostToACMEIngress() {
  local ACME_HOST=$1
  if [ -z "$ACME_HOST" ]; then
      debug "addHostToACMEIngress: error, must inform a host"
      return
  fi
  debug "addHostToACMEIngress: $ACME_HOST"
  # detects ACME plugin "ingress fix"
  INGRESS_FIX=$($VKDR_KUBECTL get ingress dummy-acme -n vkdr -o yaml --ignore-not-found)
  if [ -z "$INGRESS_FIX" ]; then
    debug "addHostToACMEIngress: ingress-fix doesn't exist, ignoring ACME"
    return
  fi
  debug "addHostToACMEIngress: dumping sample ACME fix rule ('.spec.rules[0]')"
  echo "$INGRESS_FIX" | $VKDR_YQ eval '.spec.rules[0]' - > /tmp/ingress-fix.yaml
  debug "addHostToACMEIngress: patching name and dumping json"
  $VKDR_YQ e ".host = \"$ACME_HOST\"" /tmp/ingress-fix.yaml -o json > /tmp/ingress-fix.json
  if echo "$INGRESS_FIX" | grep -q "host: $ACME_HOST"; then
    debug "addHostToACMEIngress: ingress-fix already contains $ACME_HOST, maybe should patch rule but TODO, sorry"
  else
    debug "addHostToACMEIngress: ingress-fix doesn't contain $ACME_HOST, adding it"
    echo '[ { "op": "add", "path": "/spec/rules/-", "value": '$(cat /tmp/ingress-fix.json)' } ]' > /tmp/ingress-fix-patch.json
    $VKDR_KUBECTL patch ingress dummy-acme -n vkdr --type json -p "$(cat /tmp/ingress-fix-patch.json)"
  fi
}
