# Whoami

A simple HTTP service that returns information about the incoming request. Useful for testing ingress, load balancing, and network configurations.

## Overview

The whoami service deploys a lightweight container that echoes back HTTP request details including headers, hostname, and IP address. This makes it invaluable for debugging Kubernetes networking.

## Installation

### Basic Install (localhost)

```bash
vkdr whoami install
```

This installs whoami accessible at `http://whoami.localhost`.

### Custom Domain

```bash
vkdr whoami install --domain example.com
```

Installs whoami accessible at `http://whoami.example.com`.

### With TLS

```bash
vkdr whoami install --domain example.com --secure
```

Installs whoami with HTTPS enabled at `https://whoami.example.com`.

### With Custom Labels

```bash
vkdr whoami install --labels '{"team":"platform","env":"dev"}'
```

Adds custom labels to all whoami resources.

## Removal

```bash
vkdr whoami remove
```

## Testing the Service

After installation, test the service:

```bash
# Via curl (if using localhost)
curl http://whoami.localhost

# Via kubectl port-forward
kubectl port-forward svc/whoami -n vkdr 8080:80
curl http://localhost:8080
```

## Expected Output

```
Hostname: whoami-xxxxx-xxxxx
IP: 10.42.x.x
RemoteAddr: 10.42.x.x:xxxxx
GET / HTTP/1.1
Host: whoami.localhost
User-Agent: curl/x.x.x
Accept: */*
```

## Resources Created

- **Namespace**: `vkdr`
- **Deployment**: `whoami` (1 replica)
- **Service**: `whoami` (ClusterIP, port 80)
- **Ingress**: `whoami` (with configured host)

## Helm Chart

Uses the [cowboysysop/whoami](https://github.com/cowboysysop/charts/tree/master/charts/whoami) Helm chart.
