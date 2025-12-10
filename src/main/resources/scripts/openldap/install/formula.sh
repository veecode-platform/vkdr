#!/usr/bin/env bash

#
# Install OpenLDAPO
#
# Test with simple commands:
#
# ldapwhoami -H ldap://localhost:9000 -x -D "cn=admin,dc=example,dc=org" -w admin
#

VKDR_ENV_OPENLDAP_DOMAIN=$1
VKDR_ENV_OPENLDAP_SECURE=$2
VKDR_ENV_OPENLDAP_ADMIN_USER=$3
VKDR_ENV_OPENLDAP_ADMIN_PASSWORD=$4
VKDR_ENV_OPENLDAP_NODEPORT=$5
VKDR_ENV_OPENLDAP_SELF_SERVICE_PASSWORD=$6
VKDR_ENV_OPENLDAP_LDAP_ADMIN=$7

source "$(dirname "$0")/../../.util/tools-versions.sh"
source "$(dirname "$0")/../../.util/tools-paths.sh"
source "$(dirname "$0")/../../.util/log.sh"
source "$(dirname "$0")/../../.util/ingress-tools.sh"

OPENLDAP_NAMESPACE=vkdr
OPENLDAP_RELEASE_NAME=openldap
# port values override by detectClusterPorts
VKDR_HTTP_PORT=8000
VKDR_HTTPS_PORT=8001

OPENLDAP_VALUES="$(dirname "$0")/../../.util/values/openldap.yaml"

startInfos() {
  boldInfo "OpenLDAP Install"
  bold "=============================="
  boldNotice "Domain: $VKDR_ENV_OPENLDAP_DOMAIN"
  boldNotice "Secure: $VKDR_ENV_OPENLDAP_SECURE"
  boldNotice "Admin User: $VKDR_ENV_OPENLDAP_ADMIN_USER"
  boldNotice "Admin Password: $VKDR_ENV_OPENLDAP_ADMIN_PASSWORD"
  boldNotice "NodePort: $VKDR_ENV_OPENLDAP_NODEPORT"
  boldNotice "Self-Service-Password: $VKDR_ENV_OPENLDAP_SELF_SERVICE_PASSWORD"
  boldNotice "phpLDAPadmin: $VKDR_ENV_OPENLDAP_LDAP_ADMIN"
  bold "=============================="
  boldNotice "Cluster LB HTTP port: $VKDR_HTTP_PORT"
  boldNotice "Cluster LB HTTPS port: $VKDR_HTTPS_PORT"
  bold "=============================="
}

runFormula() {
  detectClusterPorts
  startInfos
  createNamespace
  configDomain
  install
  patchInstall
  loadLDifs
  postInstall
}

createNamespace() {
  echo "
apiVersion: v1
kind: Namespace
metadata:
  name: $OPENLDAP_NAMESPACE
" | $VKDR_KUBECTL apply -f -
}

configDomain() {
  VKDR_OPENLDAP_PORT=""
  if [ "true" = "$VKDR_ENV_OPENLDAP_SECURE" ]; then
    VKDR_PROTOCOL="https"
    if [ "$VKDR_HTTPS_PORT" != "443" ]; then
      VKDR_OPENLDAP_PORT=":$VKDR_HTTPS_PORT"
    fi
  else
    VKDR_PROTOCOL="http"
    if [ "$VKDR_HTTP_PORT" != "80" ]; then
      VKDR_OPENLDAP_PORT=":$VKDR_HTTP_PORT"
    fi
  fi
  FINAL_OPENLDAP_HOSTNAME="ldap.${VKDR_ENV_OPENLDAP_DOMAIN}"
  debug "configDomain: hostname set to '$FINAL_OPENLDAP_HOSTNAME'"
}

install() {
  debug "OpenLDAP install"
  $VKDR_HELM repo add helm-openldap https://jp-gouin.github.io/helm-openldap/ 2>/dev/null || true
  $VKDR_HELM repo update helm-openldap

  $VKDR_HELM upgrade --install $OPENLDAP_RELEASE_NAME helm-openldap/openldap-stack-ha \
    --namespace $OPENLDAP_NAMESPACE \
    --values "$OPENLDAP_VALUES" \
    --set global.ldapDomain="vee.codes" \
    --set global.adminUser="$VKDR_ENV_OPENLDAP_ADMIN_USER" \
    --set global.adminPassword="$VKDR_ENV_OPENLDAP_ADMIN_PASSWORD" \
    --set global.configPassword="$VKDR_ENV_OPENLDAP_ADMIN_PASSWORD" \
    --set replicaCount=1 \
    --set phpldapadmin.enabled="$VKDR_ENV_OPENLDAP_LDAP_ADMIN" \
    --set phpldapadmin.ingress.enabled="$VKDR_ENV_OPENLDAP_LDAP_ADMIN" \
    --set phpldapadmin.ingress.hosts[0]="ldap.$VKDR_ENV_OPENLDAP_DOMAIN" \
    --set-string "phpldapadmin.env.PHPLDAPADMIN_LDAP_HOSTS=#PYTHON2BASH:[{'openldap.vkdr': [{'server': [{'tls': False}, {'base': 'dc=vee,dc=codes'}]}]}]" \
    --set ltb-passwd.enabled="$VKDR_ENV_OPENLDAP_SELF_SERVICE_PASSWORD" \
    --set ltb-passwd.ingress.hosts[0]="ldap-ssp.$VKDR_ENV_OPENLDAP_DOMAIN" \
    --set service.type=NodePort \
    --set service.ldapPortNodePort="$VKDR_ENV_OPENLDAP_NODEPORT" \
    --set-string service.enableSslLdapPort=false \
    --wait
}

postInstall() {
  boldInfo "OpenLDAP install finished!"
  #info "phpLDAPadmin available at: http://ldap.$VKDR_ENV_OPENLDAP_DOMAIN:$VKDR_HTTP_PORT"
  info "LDAP service: $OPENLDAP_RELEASE_NAME.$OPENLDAP_NAMESPACE.svc.cluster.local:389"
  info "LDAP service (host): localhost:<bound-nodeport>"  
}

patchInstall() {
  # removes TLS by brute force
  if [ "$VKDR_ENV_OPENLDAP_LDAP_ADMIN" = "true" ]; then
    debug "Patching phpLDAPadmin configmap"
    PHPLDAPADMIN_HOSTS_VALUE="#PYTHON2BASH:[{'openldap.vkdr': [{'server': [{'tls': False},{'port':389}]},{'login': [{'bind_id': 'cn=admin,dc=vee,dc=codes'}]}]}]"
    $VKDR_KUBECTL patch configmap openldap-phpldapadmin -n $OPENLDAP_NAMESPACE \
      --type merge \
      -p "{\"data\":{\"PHPLDAPADMIN_LDAP_HOSTS\":\"$PHPLDAPADMIN_HOSTS_VALUE\"}}"
    # Restart phpldapadmin pod to pick up the new config
    $VKDR_KUBECTL rollout restart deployment openldap-phpldapadmin -n $OPENLDAP_NAMESPACE
  fi
}

loadLDifs(){
  # ldifs should run auto but they did not, forcing
  # running ldapadd inside container
  debug "Loading LDIF files into OpenLDAP"
  POD_NAME=$($VKDR_KUBECTL get pods -n $OPENLDAP_NAMESPACE -l app.kubernetes.io/name=openldap-stack-ha -o jsonpath='{.items[0].metadata.name}')
  for ldif in 00-base.ldif 10-users.ldif 20-groups.ldif; do
    debug "Loading $ldif"
    $VKDR_KUBECTL exec -n $OPENLDAP_NAMESPACE "$POD_NAME" -- \
      ldapadd -x -H ldap://localhost:1389 -D "cn=admin,dc=vee,dc=codes" -w "$VKDR_ENV_OPENLDAP_ADMIN_PASSWORD" -f "/ldifs/$ldif" || true
  done
}

runFormula
