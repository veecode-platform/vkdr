#!/usr/bin/env bash

#
# use this file to update tools-versions script file with latest
#

VKDR_TOOLS_VERSION=v1.0.1
VKDR_TOOLS_KUBECTL=$(curl -L -s https://dl.k8s.io/release/stable.txt)
VKDR_TOOLS_HELM=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
VKDR_TOOLS_K3D=$(curl -s https://api.github.com/repos/k3d-io/k3d/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
VKDR_TOOLS_JQ=$(curl -s https://api.github.com/repos/jqlang/jq/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
VKDR_TOOLS_YQ=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
VKDR_TOOLS_K9S=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
VKDR_TOOLS_DECK=$(curl -s https://api.github.com/repos/kong/deck/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
VKDR_TOOLS_GLOW=$(curl -s https://api.github.com/repos/charmbracelet/glow/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
VKDR_TOOLS_VAULT=$(curl -s https://api.github.com/repos/hashicorp/vault/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
TOOLS_FILE=tools-versions.sh
# generate tools-versions file:
echo "#!/usr/bin/env bash" > $TOOLS_FILE
echo "VKDR_TOOLS_VERSION=$VKDR_TOOLS_VERSION" >> $TOOLS_FILE
echo "VKDR_TOOLS_KUBECTL=$VKDR_TOOLS_KUBECTL" >> $TOOLS_FILE
echo "VKDR_TOOLS_HELM=$VKDR_TOOLS_HELM" >> $TOOLS_FILE
echo "VKDR_TOOLS_K3D=$VKDR_TOOLS_K3D" >> $TOOLS_FILE
echo "VKDR_TOOLS_JQ=$VKDR_TOOLS_JQ" >> $TOOLS_FILE
echo "VKDR_TOOLS_YQ=$VKDR_TOOLS_YQ" >> $TOOLS_FILE
echo "VKDR_TOOLS_K9S=$VKDR_TOOLS_K9S" >> $TOOLS_FILE
echo "VKDR_TOOLS_DECK=$VKDR_TOOLS_DECK" >> $TOOLS_FILE
echo "VKDR_TOOLS_GLOW=$VKDR_TOOLS_GLOW" >> $TOOLS_FILE
echo "VKDR_TOOLS_VAULT=$VKDR_TOOLS_VAULT" >> $TOOLS_FILE
chmod +x $TOOLS_FILE