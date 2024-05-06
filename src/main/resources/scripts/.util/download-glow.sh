#!/usr/bin/env bash

VKDR_HOME=~/.vkdr
VKDR_GLOW=$VKDR_HOME/bin/glow
VKDR_TOOLS_GLOW=${1:-v1.5.1}

# Define the base URL for the downloads
BASE_URL="https://github.com/charmbracelet/glow/releases/download/$VKDR_TOOLS_GLOW"
# Determine the Operating System and Machine Architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

# Determine the right binary based on OS and architecture
case "$OS" in
    "Darwin")
        case "$ARCH" in
            "x86_64")
                FILE="glow_Darwin_x86_64.tar.gz"
                ;;
            "arm64")
                FILE="glow_Darwin_arm64.tar.gz"
                ;;
            *)
                echo "Unsupported architecture: $ARCH"
                exit 2
                ;;
        esac
        ;;
    "Linux")
        case "$ARCH" in
            "x86_64")
                FILE="glow_Linux_x86_64.tar.gz"
                ;;
            "arm64")
                FILE="glow_Linux_arm64.tar.gz"
                ;;
            *)
                echo "Unsupported architecture: $ARCH"
                exit 2
                ;;
        esac
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

# Construct the full download URL
URL="$BASE_URL/$FILE"

# Download the file
echo "Downloading $FILE..."
curl -L $URL -o "/tmp/$FILE"

# Optional: Add instructions to decompress the file if needed
echo "Decompressing $FILE..."
tar -xzf "/tmp/$FILE" -C $VKDR_HOME/bin/

echo "Download and decompression complete."
