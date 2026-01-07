#!/usr/bin/env bash

# V2 paths: relative to formulas/vault/init/
FORMULA_DIR="$(dirname "$0")"
SHARED_DIR="$FORMULA_DIR/../../_shared"
META_DIR="$FORMULA_DIR/../_meta"

source "$SHARED_DIR/lib/tools-versions.sh"
source "$SHARED_DIR/lib/tools-paths.sh"
source "$SHARED_DIR/lib/log.sh"

VAULT_NAMESPACE=vkdr
VAULT_STATUS="none"
VAULT_DEV_MODE="false"

startInfos() {
  boldInfo "Vault Init"
  bold "=============================="
  bold "=============================="
}

runFormula() {
  startInfos
  createNamespace
  getVaultAddress
  getVaultStatus
  status=$?
  if [ $status -ne 0 ]; then exit $status; fi
  initVault
}

initVault() {
  debug "initVault: run vault init/unseal, current status: '$VAULT_STATUS'"
  case "$VAULT_STATUS" in
    uninitialized)
      doInitVault
      doUnsealVault
      doEnableEngines
      ;;
    sealed)
      doUnsealVault
      doEnableEngines
      ;;
    *)
      debug "initVault: vault is already initialized and unsealed"
      doEnableEngines
      ;;
  esac
}

doInitVault () {
  debug "initVault: initializing vault..."
  $VKDR_KUBECTL -n $VAULT_NAMESPACE exec vault-0 -- vault operator init \
      -key-shares=1 \
      -key-threshold=1 \
      -format=json > /tmp/cluster-keys.json
  debug "initVault: vault initialized, saving unseal keys and root token into 'vault-keys' secret."
  UNSEAL_KEY=$(cat /tmp/cluster-keys.json | $VKDR_JQ -r ".unseal_keys_b64[0]")
  ROOT_TOKEN=$(cat /tmp/cluster-keys.json | $VKDR_JQ -r ".root_token")
  $VKDR_KUBECTL create secret generic vault-keys -n $VAULT_NAMESPACE \
      --from-literal=unseal-key="$UNSEAL_KEY" \
      --from-literal=root-token="$ROOT_TOKEN"
  debug "initVault: keys saved into 'vault-keys' secret!"
}

doUnsealVault () {
  debug "doUnsealVault: unsealing vault..."
  UNSEAL_KEY=$(cat /tmp/cluster-keys.json | $VKDR_JQ -r ".unseal_keys_b64[0]")
  $VKDR_KUBECTL -n $VAULT_NAMESPACE exec vault-0 -- vault operator unseal "$UNSEAL_KEY" > /dev/null
  debug "doUnsealVault: vault unsealed!"
}

doEnableEngines () {
  debug "doEnableEngines: fetching token"
  ROOT_TOKEN=$($VKDR_KUBECTL get secret vault-keys -n vkdr -o jsonpath='{.data}' | $VKDR_JQ -r '."root-token"' | base64 --decode)
  #debug "doEnableEngines: token $ROOT_TOKEN"
  debug "doEnableEngines: listing enabled vault engines..."
  VAULT_ENGINES_JSON=$($VKDR_KUBECTL -n $VAULT_NAMESPACE exec vault-0 -- env VAULT_TOKEN=$ROOT_TOKEN vault secrets list -format=json)
  debug "doEnableEngines: enabling vault engines..."
  if echo "$VAULT_ENGINES_JSON" | $VKDR_JQ -e '."secret/"' > /dev/null; then
    debug "doEnableEngines: the kv engine 'secret/' already exists, skipping it."
  else
    debug "doEnableEngines: enabling kv-v2 secrets engine at 'secrets/'"
    $VKDR_KUBECTL -n $VAULT_NAMESPACE exec vault-0 -- env VAULT_TOKEN=$ROOT_TOKEN vault secrets enable -path=secret kv-v2
  fi
  if echo "$VAULT_ENGINES_JSON" | $VKDR_JQ -e '."database/"' > /dev/null; then
    debug "doEnableEngines: the kv engine 'database/' already exists, skipping it."
  else
    debug "doEnableEngines: enabling database secrets engine at 'database/'"
    $VKDR_KUBECTL -n $VAULT_NAMESPACE exec vault-0 -- env VAULT_TOKEN=$ROOT_TOKEN vault secrets enable database
  fi
}

getVaultAddress() {
  VAULT_ADDR="http://vault.localhost:8000"
}

getVaultStatus() {
  debug "getVaultStatus: detecting vault status..."
  $VKDR_KUBECTL -n $VAULT_NAMESPACE exec vault-0 -- vault status -format=json > /tmp/vault-status.json 2>/tmp/vault-status.log
  status=$?
  # Check the exit status (0 and 2 are valid)
  if [ $status -ne 0 ] && [ $status -ne 2 ]; then
    error "getVaultStatus: error, maybe vault is not running (rc = $status), aborting. Check log in /tmp/vault-status.log file"
    return $status
  fi
  if ! isValidJson /tmp/vault-status.json; then
    error "getVaultStatus: error, invalid json from 'vault status', aborting. Check contexts and log in /tmp/vault-status[.log/.json] files"
    return 1
  fi
  debug "getVaultStatus: 'vault status' returned a valid JSON"
  if [ "false" = "$($VKDR_JQ ".initialized" /tmp/vault-status.json)" ]; then
    VAULT_STATUS="uninitialized"
  elif [ "true" = "$($VKDR_JQ ".sealed" /tmp/vault-status.json)" ]; then
    VAULT_STATUS="sealed"
  else
    VAULT_STATUS="ready"
  fi
  debug "getVaultStatus: detected '$VAULT_STATUS' status"
}

createNamespace() {
  debug "Create namespace '$VAULT_NAMESPACE'"
  echo "
apiVersion: v1
kind: Namespace
metadata:
  name: $VAULT_NAMESPACE
" | $VKDR_KUBECTL apply -f -
}

isValidJson() {
  json_file=$1
  # Check if the file is empty
  if [ ! -s "$json_file" ]; then
      debug "isValidJson: the file '$json_file' is empty or does not exist."
      exit 1
  fi
  $VKDR_JQ empty $json_file > /dev/null 2>&1
  status=$?
  if [ $status -eq 0 ]; then
      debug "isValidJson: the file '$json_file' is a valid JSON."
  else
      debug "isValidJson: the file '$json_file' is not a valid JSON."
  fi
  return $status
}

runFormula
