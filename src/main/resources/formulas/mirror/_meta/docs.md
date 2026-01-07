# Container Image Mirrors <!-- omit in toc -->

This feature allows you to configure container image mirrors for your Kubernetes cluster, helping to speed up image pulls and reduce external bandwidth usage.

- [Overview](#overview)
- [Listing Configured Mirrors](#listing-configured-mirrors)
- [Adding a New Mirror](#adding-a-new-mirror)
- [Removing a Mirror](#removing-a-mirror)
- [How Mirrors Work](#how-mirrors-work)
- [Configuration File](#configuration-file)

## Overview

Container image mirrors provide a way to cache and serve container images from a local or internal registry, reducing the need to pull images directly from external registries like Docker Hub. This can significantly improve deployment times and reduce external bandwidth usage.

## Listing Configured Mirrors

To view all currently configured container image mirrors:

```sh
vkdr mirror list
```

This command displays the contents of the mirror registry configuration file located at `~/.vkdr/scripts/.util/configs/mirror-registry.yaml`.

## Adding a New Mirror

To add a new mirror host to your configuration:

```sh
vkdr mirror add --host <hostname>
```

Where `<hostname>` is the registry hostname you want to mirror (e.g., `docker.io`, `gcr.io`, `quay.io`).

This will add a new entry to the mirror configuration with the following structure:

```yaml
mirrors:
  "hostname":
    endpoint:
      - http://host.k3d.internal:6001
```

The port number is automatically incremented for each new endpoint, starting from 6000.

## Removing a Mirror

To remove an existing mirror from your configuration:

```sh
vkdr mirror remove --host <hostname>
```

Where `<hostname>` is the registry hostname of the mirror you want to remove (e.g., `docker.io`, `gcr.io`, `quay.io`).

This command will:
1. Stop the running mirror registry container if it exists
2. Remove the mirror entry from the configuration file
3. Clean up any empty configuration sections

## How Mirrors Work

When a container image is requested from a registry that has a mirror configured, Kubernetes will first attempt to pull the image from the mirror. If the image is not available in the mirror, it will be pulled from the original registry and cached in the mirror for future use.

This process is transparent to users and applications, as the mirror configuration is handled at the container runtime level.

**Important:** please note that mirrors are started during the `vkdr infra start` command (or its alias `vkdr infra up`), so you need to restart the cluster after adding a new mirror.

## Configuration File

The mirror configuration is stored in YAML format at:

```
~/.vkdr/scripts/.util/configs/mirror-registry.yaml
```

The file follows the containerd registry configuration format with a `mirrors` section containing registry hostnames and their corresponding endpoints.

Example configuration with multiple mirrors:

```yaml
mirrors:
  "docker.io":
    endpoint:
      - http://host.k3d.internal:6000
  "gcr.io":
    endpoint:
      - http://host.k3d.internal:6001
  "quay.io":
    endpoint:
      - http://host.k3d.internal:6002
```

Each mirror entry consists of a registry hostname and one or more endpoints that serve as mirrors for that registry.
