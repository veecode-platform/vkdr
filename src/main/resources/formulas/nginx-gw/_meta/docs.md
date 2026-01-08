# vkdr nginx-gw

Use these commands to install and manage NGINX Gateway Fabric in your `vkdr` cluster.

NGINX Gateway Fabric is an implementation of the Kubernetes Gateway API using NGINX as the data plane. It provides a modern, standardized way to configure traffic routing in Kubernetes.

## Gateway API vs Ingress

The Gateway API is the evolution of the Ingress API, offering:
- Role-based configuration (infrastructure vs application teams)
- More expressive routing rules
- Better support for TCP/UDP traffic
- Standardized API across implementations

## vkdr nginx-gw install

Install NGINX Gateway Fabric in your cluster.

```bash
vkdr nginx-gw install [--node-ports=<node_ports>]
```

### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--node-ports` | NodePorts for http/https (e.g., `30000,30001` or `*`) | (none) |

### What Gets Installed

1. **Gateway API CRDs** - The standard Kubernetes Gateway API custom resources
2. **NGINX Gateway Fabric** - The controller and NGINX data plane
3. **GatewayClass** - Named `nginx` for creating Gateways

### Examples

#### Basic Installation

```bash
vkdr infra up
vkdr nginx-gw install
# Access via http://localhost:8000 and https://localhost:8001
```

#### With Custom Ports

Start the cluster with custom HTTP/HTTPS ports:

```bash
vkdr infra start --http 80 --https 443
vkdr nginx-gw install
# Access via http://localhost and https://localhost
```

#### Using NodePorts

When using NodePort mode instead of LoadBalancer:

```bash
# Start cluster with nodeports
vkdr infra start --nodeports 2

# Install NGINX Gateway Fabric with NodePort
vkdr nginx-gw install --node-ports 30000,30001
# Or use '*' for defaults
vkdr nginx-gw install --node-ports '*'

# Access via http://localhost:9000 and https://localhost:9001
```

## vkdr nginx-gw remove

Remove NGINX Gateway Fabric from your cluster.

```bash
vkdr nginx-gw remove
```

**Note:** This removes the NGINX Gateway Fabric controller but keeps the Gateway API CRDs installed.

### Example

```bash
vkdr nginx-gw remove
```

## vkdr nginx-gw explain

Explain NGINX Gateway Fabric setup and configuration options.

```bash
vkdr nginx-gw explain
```

## Using Gateway API Resources

### Creating a Gateway

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-gateway
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
```

### Creating an HTTPRoute

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-route
spec:
  parentRefs:
  - name: my-gateway
  hostnames:
  - "example.localhost"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: my-service
      port: 80
```

## Complete Example

### Quick Development Setup

```bash
# Start cluster
vkdr infra up

# Install NGINX Gateway Fabric
vkdr nginx-gw install

# Test with whoami
vkdr whoami install
curl http://whoami.localhost:8000

# Clean up
vkdr whoami remove
vkdr nginx-gw remove
vkdr infra stop
```

## NGINX Gateway Fabric vs NGINX Ingress Controller

| Feature | Gateway Fabric | Ingress Controller |
|---------|---------------|-------------------|
| API | Gateway API | Ingress API |
| Configuration | Gateway/HTTPRoute CRDs | Ingress + Annotations |
| Role separation | Yes (Infra/App teams) | Limited |
| TCP/UDP | Native support | Via ConfigMap |
| Future-proof | Gateway API is the future | Legacy but stable |

### When to Use NGINX Gateway Fabric

- New projects starting fresh
- Need Gateway API features
- Want role-based configuration
- Planning for future Kubernetes standards

### When to Use NGINX Ingress Controller

- Existing projects using Ingress
- Simple HTTP/HTTPS routing needs
- Extensive existing documentation/examples
