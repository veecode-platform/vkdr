# vkdr infra

The `vkdr infra` commands are used to manage the local cluster where `vkdr` installs tools and applications.

## vkdr infra start

Start the local `vkdr` cluster with configurable options. The cluster is a single-node `k3d` cluster with opinionated settings and optimizations.

This command also starts a pass-through local registry on port 6000. All image pulls from the cluster are redirected to this local registry transparently, helping avoid Docker Hub rate limits.

```bash
vkdr infra start [--traefik] [--agents=<k3d_agents>] \
  [--http=<http_port>] [--https=<https_port>] [-k=<api_port>] \
  [--nodeport-base=<nodeport_base>] [--nodeports=<nodeports>] [-v=<volumes>]
```

### Flags

| Flag | Shorthand | Description | Default |
|------|-----------|-------------|---------|
| `--http` | | Ingress controller external HTTP port | `8000` |
| `--https` | | Ingress controller external HTTPS port | `8001` |
| `--api-port` | `-k` | Kubernetes API port | (random) |
| `--agents` | | Number of k3d agents to start | `0` |
| `--traefik` | | Enable Traefik ingress controller | `false` |
| `--nodeports` | | Number of exposed nodeports | `0` |
| `--nodeport-base` | | Starting port for nodeport mapping | `9000` |
| `--volumes` | `-v` | Volumes to mount (comma-separated `hostPath:mountPath`) | (none) |

### Examples

Start with Traefik as ingress controller:

```bash
vkdr infra start --traefik
# Access via http://localhost:8000 and https://localhost:8001
```

Start without ingress (install one separately):

```bash
vkdr infra start --http 80 --https 443
vkdr nginx install --default-ic
```

Start with nodeports for services like Kong NodePort mode:

```bash
vkdr infra start --nodeports 2
# Ports 9000 and 9001 are now available for NodePort services
```

Start with custom volumes:

```bash
vkdr infra start --traefik -v "/data/app:/app,/data/config:/config"
```

Start with k3d agents for multi-node testing:

```bash
vkdr infra start --traefik --agents 2
```

## vkdr infra up

Shortcut for `vkdr infra start` with all defaults. Starts the cluster without an ingress controller.

```bash
vkdr infra up
```

### Example

```bash
vkdr infra up
# Cluster running on ports 8000/8001, no ingress
```

## vkdr infra stop

Stop the local `vkdr` cluster with options.

```bash
vkdr infra stop [--registry]
```

### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--registry` | Delete builtin cache/mirror registries | `false` |

### Examples

Stop the cluster (keep registry):

```bash
vkdr infra stop
```

Stop and delete registries:

```bash
vkdr infra stop --registry
```

## vkdr infra down

Shortcut for `vkdr infra stop` with all defaults.

```bash
vkdr infra down
```

### Example

```bash
vkdr infra down
```

## vkdr infra expose

Expose the local `vkdr` cluster admin port to the internet using a public Cloudflare tunnel.

```bash
vkdr infra expose [--off]
```

### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--off` | Terminate the tunnel | `false` |

### Examples

Start the tunnel:

```bash
vkdr infra expose
# A temporary kubeconfig file is created at ~/.vkdr/tmp/kconfig
```

Stop the tunnel:

```bash
vkdr infra expose --off
```

**Warning:** Exposing your cluster to the internet has security implications. This is useful for testing remote access, but be aware of the risks. The tunnel provides a public URL to your cluster's Kubernetes API.

## vkdr infra createToken

Create a service account token for accessing the cluster.

```bash
vkdr infra createToken [--json] [--duration=<duration>]
```

### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--duration` | Token duration (e.g., `24h`, `7d`) | (default) |
| `--json` | Output in JSON format | `false` |

### Examples

Create a token with default duration:

```bash
vkdr infra createToken
```

Create a token valid for 7 days:

```bash
vkdr infra createToken --duration 7d
```

Create a token and output as JSON:

```bash
vkdr infra createToken --json --duration 24h
```

## vkdr infra getca

Get the CA (Certificate Authority) data from the vkdr cluster.

```bash
vkdr infra getca [--json]
```

### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--json` | Output in JSON format | `false` |

### Examples

Get CA data:

```bash
vkdr infra getca
```

Get CA data as JSON:

```bash
vkdr infra getca --json
```

## Complete Examples

### Basic Development Setup

```bash
# Start cluster with Traefik
vkdr infra start --traefik

# Install a test app
vkdr whoami install
curl http://whoami.localhost:8000

# Clean up
vkdr whoami remove
vkdr infra stop
```

### Production-like Setup

```bash
# Start cluster with custom ports
vkdr infra start --http 80 --https 443

# Install Kong as ingress
vkdr kong install --default-ic -s

# Install services
vkdr postgres install -w
vkdr keycloak install
vkdr devportal install

# Clean up
vkdr infra stop
```

### Remote Access Setup

```bash
# Start cluster
vkdr infra start --traefik

# Expose to internet
vkdr infra expose

# Get credentials for remote access
vkdr infra createToken --duration 24h
vkdr infra getca

# Use ~/.vkdr/tmp/kconfig for remote kubectl access

# When done
vkdr infra expose --off
vkdr infra stop
```
