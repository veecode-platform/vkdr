# vkdr nginx

Use these commands to install and manage NGinx as an ingress controller in your `vkdr` cluster.

NGinx is a widely-used, high-performance ingress controller that's simple to configure and well-documented.

## vkdr nginx install

Install NGinx ingress controller in your cluster.

```bash
vkdr nginx install [--default-ic] [--node-ports=<node_ports>]
```

### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--default-ic` | Make NGinx the cluster's default ingress controller | `false` |
| `--node-ports` | NodePorts for http/https (e.g., `30000,30001` or `*`) | (none) |

### Examples

#### Basic Installation

```bash
vkdr infra up
vkdr nginx install --default-ic
# Access via http://localhost:8000 and https://localhost:8001
```

#### With Custom Ports

Start the cluster with custom HTTP/HTTPS ports:

```bash
vkdr infra start --http 80 --https 443
vkdr nginx install --default-ic
# Access via http://localhost and https://localhost
```

#### Using NodePorts

When using NodePort mode instead of LoadBalancer:

```bash
# Start cluster with nodeports
vkdr infra start --nodeports 2

# Install NGinx with NodePort
vkdr nginx install --default-ic --node-ports 30000,30001
# Or use '*' for defaults
vkdr nginx install --default-ic --node-ports '*'

# Access via http://localhost:9000 and https://localhost:9001
```

## vkdr nginx remove

Remove NGinx ingress controller from your cluster.

```bash
vkdr nginx remove
```

### Example

```bash
vkdr nginx remove
```

## vkdr nginx explain

Explain NGinx ingress controller setup and configuration options.

```bash
vkdr nginx explain
```

## Complete Examples

### Quick Development Setup

```bash
# Start cluster
vkdr infra up

# Install NGinx
vkdr nginx install --default-ic

# Test with whoami
vkdr whoami install
curl http://whoami.localhost:8000

# Clean up
vkdr whoami remove
vkdr nginx remove
vkdr infra stop
```

### Production-like Setup

```bash
# Start cluster with standard ports
vkdr infra start --http 80 --https 443

# Install NGinx as default ingress
vkdr nginx install --default-ic

# Install applications
vkdr keycloak install -s
vkdr postgres install

# Clean up
vkdr infra stop
```

## NGinx vs Other Ingress Controllers

| Feature | NGinx | Traefik | Kong |
|---------|-------|---------|------|
| Complexity | Simple | Simple | Medium |
| Configuration | Annotations | Labels/Annotations | CRDs |
| API Gateway | Basic | Basic | Advanced |
| Best for | General purpose | Quick setup | API management |

### When to Use NGinx

- Standard ingress needs
- Familiarity with NGinx configuration
- Wide community support
- Simple annotation-based configuration
