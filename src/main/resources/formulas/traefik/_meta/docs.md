# vkdr traefik

Use these commands to install and manage Traefik as an ingress controller in your `vkdr` cluster.

Traefik is a modern HTTP reverse proxy and load balancer that makes deploying microservices easy. It can be installed as part of the cluster startup or separately.

## vkdr traefik install

Install Traefik ingress controller in your cluster.

```bash
vkdr traefik install [-s] [--default-ic] [-d=<domain>] \
  [--node-ports=<node_ports>]
```

### Flags

| Flag | Shorthand | Description | Default |
|------|-----------|-------------|---------|
| `--domain` | `-d` | Domain name for the generated ingress | `localhost` |
| `--secure` | `-s` | Enable HTTPS | `false` |
| `--default-ic` | | Make Traefik the cluster's default ingress controller | `false` |
| `--node-ports` | | NodePorts for http/https (e.g., `30000,30001` or `*`) | (none) |

### Examples

#### Basic Installation

Install Traefik as the default ingress controller:

```bash
vkdr infra up
vkdr traefik install --default-ic
# Access at http://localhost:8000
```

#### Quick Start with infra

You can also enable Traefik directly when starting the cluster:

```bash
vkdr infra start --traefik
# Traefik is automatically installed as default ingress
```

#### With Custom Domain and HTTPS

```bash
vkdr traefik install -d example.com -s --default-ic
```

#### Using NodePorts

When using NodePort mode:

```bash
# Start cluster with nodeports exposed
vkdr infra start --nodeports 2

# Install Traefik with NodePort
vkdr traefik install --node-ports 30000,30001 --default-ic
# Or use '*' for default ports 30000,30001
vkdr traefik install --node-ports '*' --default-ic

# Access via http://localhost:9000
```

## vkdr traefik remove

Remove Traefik from your cluster.

```bash
vkdr traefik remove
```

### Example

```bash
vkdr traefik remove
```

## vkdr traefik explain

Explain Traefik ingress controller setup and configuration options.

```bash
vkdr traefik explain
```

## Complete Examples

### Quick Development Setup

The fastest way to get started:

```bash
# Start cluster with Traefik
vkdr infra start --traefik

# Test with whoami
vkdr whoami install
curl http://whoami.localhost:8000

# Clean up
vkdr whoami remove
vkdr infra stop
```

### Manual Installation

If you need more control:

```bash
# Start cluster without ingress
vkdr infra up

# Install Traefik separately
vkdr traefik install --default-ic

# Test
curl localhost:8000
# Returns 404 (no services yet)

vkdr whoami install
curl http://whoami.localhost:8000

# Clean up
vkdr whoami remove
vkdr traefik remove
```

### Custom Ports

```bash
# Start cluster with custom ports
vkdr infra start --http 80 --https 443

# Install Traefik
vkdr traefik install --default-ic

# Access on standard ports
curl http://whoami.localhost
```

## Traefik vs Other Ingress Controllers

| Feature | Traefik | NGinx | Kong |
|---------|---------|-------|------|
| Setup complexity | Simple | Simple | Medium |
| Built-in dashboard | Yes | No | Yes (Enterprise) |
| API Gateway features | Basic | Basic | Advanced |
| ACME/Let's Encrypt | Built-in | Via cert-manager | Plugin |
| Best for | Development, simple production | General purpose | API management |

### When to Use Traefik

- Quick local development
- Simple ingress needs
- Automatic HTTPS with Let's Encrypt
- When you want minimal configuration

### When to Use Kong Instead

- API gateway features needed (rate limiting, auth, etc.)
- VeeCode DevPortal (requires Kong)
- Enterprise features needed

## Differences from Bundled Traefik

When you run `vkdr infra start --traefik`, k3d includes a basic Traefik instance. The standalone Traefik installed by `vkdr traefik install`:
- Uses the official Traefik Helm chart
- Provides more configuration options
- Includes a secured dashboard UI
- Allows custom domain and TLS settings
- Can be configured as the default ingress controller

### Dashboard Access

After installation, the Traefik dashboard is available at:
```
https://traefik-ui.<your-domain>
```

Default credentials:
- Username: admin
- Password: vkdr123

### NodePort Options

```sh
vkdr traefik install --node-ports 30000,30001  # Specific ports
vkdr traefik install --node-ports '*'          # Default 30000,30001
```

Using `--node-ports` changes service type from LoadBalancer to NodePort.

### Compatibility

This Traefik installation is compatible with all VKDR services and can be used alongside other ingress controllers like Nginx.
