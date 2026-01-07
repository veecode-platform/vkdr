#!/usr/bin/env bash

#
# Updates tools-versions.sh with latest versions from GitHub releases.
# Run this script periodically to keep tool versions up to date.
#
# Usage: ./generate-tools-versions.sh
#

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLS_FILE="$SCRIPT_DIR/../lib/tools-versions.sh"

echo "Fetching latest tool versions..."

VKDR_TOOLS_VERSION=v1.0.1
echo "  kubectl..."
VKDR_TOOLS_KUBECTL=$(curl -L -s https://dl.k8s.io/release/stable.txt)
echo "  helm..."
VKDR_TOOLS_HELM=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
echo "  k3d..."
VKDR_TOOLS_K3D=$(curl -s https://api.github.com/repos/k3d-io/k3d/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
echo "  jq..."
VKDR_TOOLS_JQ=$(curl -s https://api.github.com/repos/jqlang/jq/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
echo "  yq..."
VKDR_TOOLS_YQ=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
echo "  k9s..."
VKDR_TOOLS_K9S=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
echo "  deck..."
VKDR_TOOLS_DECK=$(curl -s https://api.github.com/repos/kong/deck/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
echo "  glow..."
VKDR_TOOLS_GLOW=$(curl -s https://api.github.com/repos/charmbracelet/glow/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
echo "  vault..."
VKDR_TOOLS_VAULT=$(curl -s https://api.github.com/repos/hashicorp/vault/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
# generate tools-versions file:
echo ""
echo "Writing to: $TOOLS_FILE"
cat > "$TOOLS_FILE" << EOF
#!/usr/bin/env bash
VKDR_TOOLS_VERSION=$VKDR_TOOLS_VERSION
VKDR_TOOLS_KUBECTL=$VKDR_TOOLS_KUBECTL
VKDR_TOOLS_HELM=$VKDR_TOOLS_HELM
VKDR_TOOLS_K3D=$VKDR_TOOLS_K3D
VKDR_TOOLS_JQ=$VKDR_TOOLS_JQ
VKDR_TOOLS_YQ=$VKDR_TOOLS_YQ
VKDR_TOOLS_K9S=$VKDR_TOOLS_K9S
VKDR_TOOLS_DECK=$VKDR_TOOLS_DECK
VKDR_TOOLS_GLOW=$VKDR_TOOLS_GLOW
VKDR_TOOLS_VAULT=$VKDR_TOOLS_VAULT
EOF
chmod +x "$TOOLS_FILE"

echo ""
echo "Updated versions:"
echo "  kubectl: $VKDR_TOOLS_KUBECTL"
echo "  helm:    $VKDR_TOOLS_HELM"
echo "  k3d:     $VKDR_TOOLS_K3D"
echo "  jq:      $VKDR_TOOLS_JQ"
echo "  yq:      $VKDR_TOOLS_YQ"
echo "  k9s:     $VKDR_TOOLS_K9S"
echo "  deck:    $VKDR_TOOLS_DECK"
echo "  glow:    $VKDR_TOOLS_GLOW"
echo "  vault:   $VKDR_TOOLS_VAULT"
echo ""
echo "Done!"