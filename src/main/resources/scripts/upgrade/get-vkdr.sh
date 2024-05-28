#!/bin/bash

# Function to handle script interruption
cleanup() {
    echo "Script interrupted. Exiting without completing installation."
    exit 1
}

# Install trap to catch CTRL+C and call cleanup function
trap cleanup SIGINT

download_file() {
    if command -v wget > /dev/null; then
        echo "Downloading $FILENAME to $TEMP_FILE using wget..."
        #wget -q --show-progress -O "$TEMP_FILE" "$DOWNLOAD_URL"
        wget -q -O "$TEMP_FILE" "$DOWNLOAD_URL"
    else
        echo "wget not available, using curl..."
        echo "Downloading $FILENAME to $TEMP_FILE using curl..."
        curl -L "$DOWNLOAD_URL" -o "$TEMP_FILE"
    fi
}

# GitHub user and repository name
USER="veecode-platform"
REPO="vkdr"

# Get the latest release data from GitHub API
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$USER/$REPO/releases/latest")

# Extract the tag name (version) from the release data
TAG_NAME=$(echo $LATEST_RELEASE | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')

# Detect platform and architecture
OS=$(uname -s)
ARCH=$(uname -m)

# Convert architecture to the required format
if [[ $ARCH == "x86_64" ]]; then
    ARCH="amd64"
elif [[ $ARCH == "arm64" ]]; then
    ARCH="arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Build the filename based on OS and architecture
if [[ $OS == "Linux" ]]; then
    FILENAME="vkdr-linux-$ARCH"
elif [[ $OS == "Darwin" ]]; then
    FILENAME="vkdr-osx-$ARCH"
else
    echo "Unsupported OS: $OS"
    exit 1
fi

# Build the download URL
DOWNLOAD_URL="https://github.com/$USER/$REPO/releases/download/$TAG_NAME/$FILENAME"

# Create a temporary file in /tmp
TEMP_FILE=$(mktemp /tmp/$FILENAME.XXXXXX)

# Download the file using wget or curl
download_file

# Check if /usr/local/bin exists and move the file
if [ -d "/usr/local/bin" ]; then
    echo "Moving $TEMP_FILE to /usr/local/bin/vkdr (may require sudo)..."
    if [ "$(id -u)" -eq 0 ]; then
      mv $TEMP_FILE /usr/local/bin/vkdr
      chmod +x /usr/local/bin/vkdr
    else
      sudo mv $TEMP_FILE /usr/local/bin/vkdr
      sudo chmod +x /usr/local/bin/vkdr
    fi
    echo "Download and installation completed, VKDR is now available at '/usr/local/bin/vkdr'"
else
    echo "/usr/local/bin does not exist. Please check your installation."
    exit 1
fi
