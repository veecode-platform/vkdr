# Traefik Ingress Controller <!-- omit in toc -->

This feature allows you to install Traefik ingress controller in your Kubernetes cluster.

- [Overview](#overview)
- [Differences from Bundled Traefik](#differences-from-bundled-traefik)
- [Installation](#installation)
  - [Options](#options)
- [Dashboard Access](#dashboard-access)
- [Removal](#removal)
- [Use Cases](#use-cases)
- [Compatibility](#compatibility)

## Overview
This command installs the official Traefik ingress controller in your Kubernetes cluster. This is a **standalone** Traefik installation that is different from the bundled Traefik that can be optionally enabled in `vkdr infra start`.

## Differences from Bundled Traefik
When you run `vkdr infra start --traefik`, k3d includes a basic Traefik instance that is configured with minimal settings. 
The standalone Traefik installed by `vkdr traefik install`:
- Uses the official Traefik Helm chart
- Provides more configuration options
- Includes a secured dashboard UI
- Allows for custom domain and TLS settings
- Can be configured as the default ingress controller

## Installation
```
vkdr traefik install [options]
```

### Options
- `--domain <domain>`: Domain to use for Traefik (default: localhost)
- `--secure`: Enable HTTPS/TLS (default: false)
- `--default-ic`: Make Traefik the default ingress controller (default: false)
- `--node-ports <ports>`: Use specific node ports for HTTP/HTTPS endpoints
  - Example: '30000,30001'
  - Using '*' means '30000,30001'
  - This changes service type from LoadBalancer to NodePort

## Dashboard Access
After installation, the Traefik dashboard is available at:
```
https://traefik-ui.<your-domain>
```

Default credentials:
- Username: admin
- Password: vkdr123

## Removal
To remove the Traefik installation:
```
vkdr traefik remove
```

## Use Cases
- When you need more advanced ingress capabilities than the basic K3d bundled Traefik
- When you want to configure custom middleware, routes, or TLS settings
- When you need a visual dashboard to monitor and manage your ingress traffic

## Compatibility
This Traefik installation is compatible with all other VKDR services and can be used alongside other ingress controllers like Nginx.
