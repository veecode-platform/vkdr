#!/usr/bin/env bash

#
# addHostToACMEIngress: the ACME ingress is an exception rule to the
# forced https redirect. ACME plugin requires port 80 to work.
#
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
    debug "addHostToACMEIngress: ingress-fix already contains $ACME_HOST, maybe should patch rule but will just ignore it, sorry"
  else
    debug "addHostToACMEIngress: ingress-fix doesn't contain $ACME_HOST, adding it"
    echo '[ { "op": "add", "path": "/spec/rules/-", "value": '$(cat /tmp/ingress-fix.json)' } ]' > /tmp/ingress-fix-patch.json
    $VKDR_KUBECTL patch ingress dummy-acme -n vkdr --type json -p "$(cat /tmp/ingress-fix-patch.json)"
  fi
}

detectACMEPlugin() {
  # detects ACME global plugin
  debug "detectACMEPlugin: Detecting ACME plugin..."
  kubectl get kongclusterplugin global-acme-plugin -n vkdr 2>&1 > /dev/null
  exit_status=$?
  if [ $exit_status -eq 0 ]; then
    debug "detectACMEPlugin: ACME plugin detected"
    return 0
  fi
  debug "detectACMEPlugin: ACME plugin NOT detected"
  return 1
}

getClusterPortsJson() {
  MAPPINGS="$(LOG_LEVEL=error $VKDR_K3D cluster list -o json | $VKDR_JQ '.[] | select(.name == "vkdr-local") | .nodes[].portMappings')"
  HTTP_PORT="$(echo "$MAPPINGS" | $VKDR_JQ -r '.["80/tcp"][0].HostPort' | head -n 1)"
  HTTPS_PORT="$(echo "$MAPPINGS" | $VKDR_JQ -r '.["443/tcp"][0].HostPort' | head -n 1)"
  echo "{ \"http\": \"$HTTP_PORT\", \"https\": \"$HTTPS_PORT\" }"
}

detectClusterPorts() {
  JSON=$(getClusterPortsJson)
  if [ -z "$JSON" ]; then return 1; fi
  export VKDR_HTTP_PORT=$(echo "$JSON" | $VKDR_JQ -r '.http')
  export VKDR_HTTPS_PORT=$(echo "$JSON" | $VKDR_JQ -r '.https')
}
