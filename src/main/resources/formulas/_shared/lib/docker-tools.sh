#!/usr/bin/env bash

checkDockerEngine() {
    # check if CLI is available
    if ! command -v docker &> /dev/null; then
        error "checkDockerEngine: Docker CLI or alias 'docker' could not be found, please install it first."
        exit 1
    fi
    # Check version (basic CLI functionality)
    docker --version || { error "checkDockerEngine:Docker CLI not working, please check its installation."; exit 1; }
    # Check connectivity to Docker daemon
    docker info >/dev/null 2>&1 && debug "checkDockerEngine: Docker is running and accessible." \
        || { error "checkDockerEngine: Docker CLI cannot connect to daemon, please mare sure a container engine is running."; exit 1; }
}
