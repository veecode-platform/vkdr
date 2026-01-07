#!/usr/bin/env bash

#
# Tool to help with Vault
#

getVaultAddress() {
  VAULT_ADDR="http://vault.localhost:8000"
}

getVaultToken() {
  local result="NO_TOKEN"
  #debug "getVaultToken: fetching vault token"
  result=$($VKDR_KUBECTL get secret vault-keys -n vkdr -o jsonpath='{.data}' | $VKDR_JQ -r '."root-token"' | base64 --decode)
  echo "$result"
}