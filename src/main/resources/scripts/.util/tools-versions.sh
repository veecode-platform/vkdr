VKDR_TOOLS_VERSION=v1.0.0
VKDR_TOOLS_KUBECTL=v1.29.3
VKDR_TOOLS_HELM=v3.14.3
VKDR_TOOLS_K3D=v5.6.0
VKDR_TOOLS_JQ=jq-1.7.1
VKDR_TOOLS_YQ=v4.42.1
VKDR_TOOLS_K9S=v0.32.3
VKDR_TOOLS_DECK=1.36.0

# para descobrir versões:
# KUBECTL
# curl -L -s https://dl.k8s.io/release/stable.txt
# HELM
# curl -s https://api.github.com/repos/helm/helm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
# K3D
# curl -s https://api.github.com/repos/k3d-io/k3d/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
# JQ
# curl -s https://api.github.com/repos/jqlang/jq/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
# YQ
# curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
# K9S
# curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
# DECK
# curl -s https://api.github.com/repos/kong/deck/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'