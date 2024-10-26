#!/usr/bin/env bash

# parametros posicionais na formula
VKDR_ENV_EXPOSE_OFF=$1

source "$(dirname "$0")/../../.util/log.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"

EXPOSE_NAMESPACE="vkdr-expose"
TUNNEL_NAME="vkdr-tunnel"
TUNNEL_URL=""
SA_TOKEN=""
CADATA=""

startInfos() {
  bold "=============================="
  boldInfo "VKDR Local Expose Routine"
  boldNotice "Terminate tunnel: ${VKDR_ENV_EXPOSE_OFF}"
  bold "=============================="
}

runFormula() {
  startInfos
  if [ "$VKDR_ENV_EXPOSE_OFF" = "true" ]; then
    stopTunnel
    #deleteServiceAccount
    return
  fi
  createNamespace
  createServiceAccount
  startTunnel
}

createServiceAccount() {
  debug "createServiceAccount: creating service account..."
  $VKDR_KUBECTL apply -n "$EXPOSE_NAMESPACE" -f "$(dirname "$0")/../../.util/super-admin-service-account/super-admin.yaml"
  SA_TOKEN=$($VKDR_KUBECTL get secret superadmin-token -n "$EXPOSE_NAMESPACE" -o jsonpath='{.data.token}' | base64 --decode)
}

deleteServiceAccount() {
  debug "deleteServiceAccount: removing service account..."
  $VKDR_KUBECTL delete -n "$EXPOSE_NAMESPACE" -f "$(dirname "$0")/../../.util/super-admin-service-account/super-admin.yaml"
}

stopTunnel() {
  debug "stopTunnel: deleting cloudflare tunnel if enabled..."
  set +e
  $VKDR_KUBECTL delete pod -n "$EXPOSE_NAMESPACE" "$TUNNEL_NAME" 2>/dev/null
  set -e
}

startTunnel() {
  if ! kubectl get pod -n "$EXPOSE_NAMESPACE" "$TUNNEL_NAME" > /dev/null 2>&1; then
    debug "startTunnel: expose vkdr cluster using a public cloudflare tunnel"
    $VKDR_KUBECTL run --restart=Never "$TUNNEL_NAME" --image=cloudflare/cloudflared:latest -n "$EXPOSE_NAMESPACE" \
      -- tunnel --no-tls-verify --url https://kubernetes.default.svc
  else
    debug "startTunnel: cloudflare tunnel already running, skipping..."
  fi
  getTunnelURLFromLog
  generateSAKubeConfig
}

generateSAKubeConfig() {
  debug "generateSAKubeConfig: generating kubeconfig..."
  mkdir -p ~/.vkdr/tmp
  local kconfig_src="$(dirname "$0")/../../.util/super-admin-service-account/kconfig.template"
  local kconfig_dest="$HOME/.vkdr/tmp/kconfig"
  getCAFromDomain
  local insecure_tls_verify="true"
  if [ -n "$CADATA" ]; then
    insecure_tls_verify="false"
  fi
  #cat "$kconfig_src"
  sed "s#\$TUNNEL_URL#$TUNNEL_URL#g" "$kconfig_src" | \
    sed "s/\$CADATA/$CADATA/g" | sed "s/\$SA_TOKEN/$SA_TOKEN/g" | \
    sed "s/\$NOTLSVERIFY/$insecure_tls_verify/g" > "$kconfig_dest"
  debug "generateSAKubeConfig: kubeconfig generated in $kconfig_dest"
}

getCAFromDomain() {
  if ! command -v openssl >/dev/null 2>&1; then
      debug "getCAFromDomain: no 'openssl' found in PATH, fallback to insecure kubeconfig..."
      return
  fi
  debug "getCAFromDomain: extracting domain from tunnel at '$TUNNEL_URL'..."
  # espera por erro 401 --> tunel ok
  local retries=0
  while true; do
    # Execute curl and capture the HTTP status code
    status_code=$(curl -o /dev/null -s -w "%{http_code}" "$TUNNEL_URL")
    # if 000 try again with DOH
    if [ "$status_code" -eq 000 ]; then
      status_code=$(curl --doh-url https://1.1.1.1/dns-query -o /dev/null -s -w "%{http_code}" "$TUNNEL_URL")
    fi
    # Check if the status code is 401
    if [ "$status_code" -eq 401 ]; then
      debug "getCAFromDomain: Received 401 Unauthorized (as expected, this is ok). Exiting loop."
      break
    else
      debug "getCAFromDomain: Status code: $status_code. Continuing loop..."
    fi
    if [ $retries -eq 10 ]; then
      debug "getCAFromDomain: max retries reached, exiting..."
      return
    fi
    retries=$((retries+1))
    sleep 1
  done
  if [ -n "$TUNNEL_URL" ]; then
    local domain=$(echo "$TUNNEL_URL" | awk -F[/:] '{print $4}')
    debug "getCAFromDomain: domain extracted: $domain, fetching CADATA"
    CADATA=$(openssl s_client -showcerts -servername $domain -connect $domain:443 </dev/null 2>/dev/null | \
      awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/ { print }' | base64)
    local cadata_first_10_chars="${CADATA:0:10}"
    debug "getCAFromDomain: CADATA fetched '$cadata_first_10_chars...'"
  fi
}

getTunnelURLFromLog() {
  local retries=0
  while [ "$retries" -lt 10 ]; do
    # Check if the pod is still running
    POD_STATUS=$(kubectl get pod -n "$EXPOSE_NAMESPACE" "$TUNNEL_NAME" -o jsonpath='{.status.phase}')
    case $POD_STATUS in
      "Pending")
        debug "getTunnelURLFromLog: current status is 'Pending', waiting..."
        ;;
      "ContainerCreating")
        debug "getTunnelURLFromLog: current status is 'ContainerCreating', waiting..."
        ;;
      "Running")
        debug "getTunnelURLFromLog: current status is 'Running', reading log..."
        # Check the logs of the pod and search for the string if "Running"
        local myurl
        myurl=$($VKDR_KUBECTL logs -n "$EXPOSE_NAMESPACE" "$TUNNEL_NAME" | grep -o "https.*\.trycloudflare\.com")
        if [ -n "$myurl" ]; then
          debug "getTunnelURLFromLog: tunnel URL found: $myurl"
          #echo "$myurl"
          TUNNEL_URL="$myurl"
          return
        fi
        ;;
      *)
        debug "getTunnelURLFromLog: tunnel is no longer running (current status: $POD_STATUS). Exiting."
        return
        ;;
    esac
    # Wait for a few seconds before checking again to avoid spamming the API
    debug "getTunnelURLFromLog: waiting for tunnel URL..."
    retries=$((retries+1))
    sleep 3
  done
  error "getTunnelURLFromLog: max retries reached, exiting without reading tunnel URL..."
}

createNamespace() {
  debug "Create namespace '$EXPOSE_NAMESPACE'"
  echo "
apiVersion: v1
kind: Namespace
metadata:
  name: $EXPOSE_NAMESPACE
" | $VKDR_KUBECTL apply -f -
}

runFormula
