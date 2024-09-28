#!/usr/bin/env bash

source "$(dirname "$0")/../.util/tools-versions.sh"
source "$(dirname "$0")/../.util/tools-paths.sh"
source "$(dirname "$0")/../.util/log.sh"

runFormula() {
  boldInfo "VKDR initialization"
  bold "=============================="
  local VKDR_HOME=~/.vkdr

  mkdir -p $VKDR_HOME/bin

  installArkade
  #validateKubectlVersion
  installTool "kubectl" "$VKDR_TOOLS_KUBECTL"
  #validateK3DVersion
  installTool "k3d" "$VKDR_TOOLS_K3D"
  #validateJQVersion
  installTool "jq" "$VKDR_TOOLS_JQ"
  #validateYQVersion
  installTool "yq" "$VKDR_TOOLS_YQ"
  installHelm
  installGlow
  installTool "vault" "$VKDR_TOOLS_VAULT"

  #installAWS
  #installOkteto
  #installDeck
  #installHelm
  #installBats
  #installeksctl

}

installeksctl(){
 curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
  if command -v sudo &> /dev/null; then
    sudo mv /tmp/eksctl /usr/local/bin
  else
    mv /tmp/eksctl /usr/local/bin
  fi
}

installArkade() {
  if [[ -f "$VKDR_ARKADE" ]]; then
    notice "Alex Ellis' arkade already installed. Skipping..."
  else
    info "Installing arkade..."
    # patches download script in order to change BINLOCATION
    curl -sLS https://get.arkade.dev > /tmp/arkinst.sh
    #sed "s/^export BINLOCATION=.*/export BINLOCATION=~\/\.vkdr\/bin/g" /tmp/arkinst0.sh > /tmp/arkinst.sh
    chmod +x /tmp/arkinst.sh
    #rm /tmp/arkinst0.sh
    BINLOCATION=~/.vkdr/bin /tmp/arkinst.sh 2> /dev/null
  fi
}

installAWS() {
  if [[ -f "$VKDR_AWS" ]]; then
    notice "AWS already installed. Skipping..."
  else
    info "Installing AWS..."
    # patches download script in order to change BINLOCATION
    curl -sSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip
    unzip -o -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install -i ~/.VKDR/bin -b ~/.VKDR/bin --update
  fi
}

##Install tool using arkade and get tools version from ./utils/tools-versions.sh or latest as default
installTool() {
  local toolName=$1
  local toolVersion=$2
  if [[ -f "$VKDR_HOME/bin/$toolName" ]]; then
    notice "Tool $toolName already installed. Skipping."
  else
    info "Installing $toolName $toolVersion using arkade..."
    $VKDR_HOME/bin/arkade get $toolName --version=$toolVersion --path="$VKDR_HOME/bin" --progress=false > /dev/null
    info "$toolName $toolVersion installed!"
  fi
}

installOkteto() {
  if [[ -f "$VKDR_OKTETO" ]]; then
    notice "Okteto already installed. Skipping..."
  else
    info "Installing Okteto..."
    # patches download script in order to change BINLOCATION
    curl https://get.okteto.com -sSfL -o /tmp/okteto0.sh
    sed 's|\/usr\/local\/bin|~\/\.VKDR\/bin|g ; 59,71s/^/#/' /tmp/okteto0.sh > /tmp/okteto.sh
    chmod +x /tmp/okteto.sh
    rm /tmp/okteto0.sh
    /tmp/okteto.sh 2> /dev/null
  fi
}

installHelm() {
  if [[ -f "$VKDR_HELM" ]]; then
    notice "Helm already installed. Skipping..."
  else
    info "Installing Helm..."
    # patches download script in order to change BINLOCATION
    curl -fsSL -o /tmp/get_helm0.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    sed 's|\/usr\/local\/bin|$\HOME/\.vkdr\/bin|g' /tmp/get_helm0.sh > /tmp/get_helm.sh
    chmod +x /tmp/get_helm.sh
    rm /tmp/get_helm0.sh
    /tmp/get_helm.sh --version $VKDR_TOOLS_HELM --no-sudo > /dev/null
    rm /tmp/get_helm.sh
    info "Helm installed!"
  fi
  #installHelmDiff
}

installHelmDiff (){
  if [[ -f "$VKDR_HELM" ]]; then
    if [[ -f "$HOME/.local/share/helm/plugins/helm-diff/README.md" ]]; then
      notice "Helm diff already installed. Skipping..."
    else
      info "Installing Helm diff..."
      $VKDR_HELM plugin install https://github.com/databus23/helm-diff > /dev/null
      info "Helm diff installed!"
    fi
  else
    warn "Helm not installed."
  fi
}

installDeck() {
  if [[ -f "$VKDR_DECK" ]]; then
    notice "decK already installed. Skipping..."
  else
    info "Installing decK..."
    # patches download script in order to change BINLOCATION
    curl -sL https://github.com/kong/deck/releases/download/v"${VKDR_TOOLS_DECK}"/deck_"${VKDR_TOOLS_DECK}"_linux_amd64.tar.gz -o /tmp/deck.tar.gz
    tar -xf /tmp/deck.tar.gz -C /tmp
    cp /tmp/deck ~/.vkdr/bin
    info "Deck installed!"
  fi
}

installGlow() {
  if [[ -f "$VKDR_GLOW" ]]; then
    notice "Glow already installed. Skipping..."
  else
    info "Installing Glow..."
    "$(dirname "$0")/../.util/download-glow.sh"
    info "Glow installed!"
  fi
}

echo "VKDR_TOOLS_VERSION=$VKDR_TOOLS_VERSION"
boldInfo "VKDR_TOOLS_VERSION=$VKDR_TOOLS_VERSION"
runFormula
