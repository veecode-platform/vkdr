# vkdr kong-gw

Use these commands to install and manage Kong Gateway Operator in your `vkdr` cluster.

Kong Gateway Operator is an implementation of the Kubernetes Gateway API using Kong as the data plane. It provides a modern, standardized way to configure traffic routing in Kubernetes.

## Gateway API vs Ingress

The Gateway API is the evolution of the Ingress API, offering:
- Role-based configuration (infrastructure vs application teams)
- More expressive routing rules
- Better support for TCP/UDP traffic
- Standardized API across implementations

## vkdr kong-gw install

Install Kong Gateway Operator in your cluster.

```bash
vkdr kong-gw install [--node-ports=<node_ports>] [--profile=<profile>] [--image=<image>] [--tag=<tag>]
```

### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--node-ports` | NodePorts for http/https (e.g., `30000,30001` or `*`) | (none) |
| `--profile` | Image profile: `default`, `kong`, `kong-distroless`, `oss`, `apip`, `apip-distroless` | `default` |
| `-i`, `--image` | Kong data plane image name | `kong/kong-gateway` |
| `-t`, `--tag` | Kong data plane image tag | `3.14` |

### Image Profiles

`--profile` is a shortcut for the image name/tag pairs vkdr supports:

| Profile | Image | Tag |
| --- | --- | --- |
| `default` | `kong/kong-gateway` | `3.14` (the formula default) |
| `kong` | `kong/kong-gateway` | `3.15.0.4` |
| `kong-distroless` | `kong/kong-gateway` | `3.15-distroless` |
| `oss` | `kong` | `3.9.3` |
| `apip` | `veecode/kong` | `3.10.0-veecode.10` |
| `apip-distroless` | `veecode/kong` | `3.10.0-veecode.10-distroless` |

```bash
# VeeCode APIP build, distroless
vkdr kong-gw install --profile apip-distroless

# Kong Gateway 3.15 (needs a license to keep serving traffic)
vkdr kong-gw install --profile kong

# Kong OSS
vkdr kong-gw install --profile oss
```

**Note:** the `kong` and `kong-distroless` profiles are Kong Gateway 3.15, which stops
serving traffic without a license. The `default` profile stays on 3.14 for that reason.

`--image` and `--tag` override the profile field by field, so `--profile oss --tag 3.9.1`
installs `kong:3.9.1`.

### Data Plane Image

The data plane image is pinned rather than left to the operator's default. The default
is the enterprise image `kong/kong-gateway:3.14` — `3.14` is the last release that keeps
serving traffic when no license is present, so it behaves like the OSS image out of the box.

Kong also publishes **distroless** variants, which carry no shell or package manager and
are therefore a smaller attack surface. They are the same gateway: routing, plugins and
configuration behave identically, so switching is a drop-in change. Pick one by suffixing
the tag:

```bash
# default enterprise image
vkdr kong-gw install

# distroless variant of the same release
vkdr kong-gw install --tag 3.14-distroless

# OSS image instead
vkdr kong-gw install --image kong --tag 3.9

# a specific patch release
vkdr kong-gw install --tag 3.14.0.0
```

The image is applied through the `kong-config` GatewayConfiguration, so it can be changed
by re-running `install` — the operator rolls the data plane onto the new image. Use
[`--profile`](#image-profiles) to pick a known-good pair instead of spelling both out.

### What Gets Installed

1. **Operator** (if not already installed):
   - Gateway API CRDs
   - Kong Gateway Operator controller
   - GatewayClass named `kong`

2. **TLS Certificate** (if not exists):
   - Self-signed certificate for TLS termination
   - SANs: `localhost`, `*.localhost`, `localdomain`, `*.localdomain`
   - Stored in secret `kong-gateway-tls`

3. **GatewayConfiguration** (always created/updated):
   - Named `kong-config` in `kong-system` namespace
   - Pins the data plane image (see [Data Plane Image](#data-plane-image))
   - Sets the ingress service to `NodePort` when `--node-ports` is used

4. **Gateway** (always created/updated):
   - Default Gateway named `kong` in `kong-system` namespace
   - HTTP listener on port 80
   - HTTPS listener on port 443 with TLS termination
   - Allows HTTPRoutes from all namespaces

**Note:** If the operator is already installed, only the Gateway object is created. This allows multiple `install` calls to update the Gateway configuration without reinstalling the operator.

### Examples

#### Distroless Data Plane

```bash
vkdr infra up
vkdr kong-gw install --tag 3.14-distroless
# same behaviour as the default image, smaller attack surface
```

#### Basic Installation

```bash
vkdr infra up
vkdr kong-gw install
# Access via http://localhost:8000 and https://localhost:8001
```

#### With Custom Ports

Start the cluster with custom HTTP/HTTPS ports:

```bash
vkdr infra start --http 80 --https 443
vkdr kong-gw install
# Access via http://localhost and https://localhost
```

#### Using NodePorts

When using NodePort mode instead of LoadBalancer:

```bash
# Start cluster with nodeports
vkdr infra start --nodeports 2

# Install Kong Gateway Operator with NodePort
vkdr kong-gw install --node-ports 30000,30001
# Or use '*' for defaults
vkdr kong-gw install --node-ports '*'

# Access via http://localhost:9000 and https://localhost:9001
```

## vkdr kong-gw remove

Remove Kong Gateway from your cluster.

```bash
vkdr kong-gw remove [--delete-operator]
```

### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--delete-operator` | Also remove operator and TLS secret | `false` |

### What Gets Removed

**Default behavior** (no flags):
- Removes the Gateway object named `kong`
- Removes the `kong-config` GatewayConfiguration
- **Keeps the operator and TLS secret** for quick re-creation of Gateways

**With `--delete-operator`**:
- Removes the Gateway and GatewayConfiguration (as above)
- Removes the GatewayClass
- Uninstalls the Kong Gateway Operator helm release
- Deletes the entire `kong-system` namespace (including TLS secret)
- Gateway API CRDs remain installed
- Idempotent: safe to run multiple times

### Examples

```bash
# Remove Gateway only (fast, operator stays)
vkdr kong-gw remove

# Full removal including operator and TLS secret
vkdr kong-gw remove --delete-operator
```

## vkdr kong-gw explain

Explain Kong Gateway Operator setup and configuration options.

```bash
vkdr kong-gw explain
```

## Using Gateway API Resources

### Creating a Gateway

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-gateway
spec:
  gatewayClassName: kong
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

# Install Kong Gateway Operator
vkdr kong-gw install

# Test with whoami using Gateway API
vkdr whoami install --gateway kong
curl http://whoami.localhost:8000

# Clean up
vkdr whoami remove
vkdr kong-gw remove
vkdr infra stop
```

## Kong Gateway Operator vs Kong Ingress Controller

| Feature | Gateway Operator | Ingress Controller |
|---------|-----------------|-------------------|
| API | Gateway API | Ingress API |
| Configuration | Gateway/HTTPRoute CRDs | Ingress + Annotations |
| Role separation | Yes (Infra/App teams) | Limited |
| Data Plane | Managed by operator | Self-managed |
| Future-proof | Gateway API is the future | Legacy but stable |

### When to Use Kong Gateway Operator

- New projects starting fresh
- Need Gateway API features
- Want role-based configuration
- Planning for future Kubernetes standards
- Need operator-managed data plane lifecycle

### When to Use Kong Ingress Controller

- Existing projects using Ingress
- Simple HTTP/HTTPS routing needs
- Need Kong-specific features via annotations
- Extensive existing documentation/examples
