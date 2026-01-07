# vkdr mirror

Use these commands to manage container image mirrors in your `vkdr` cluster.

Container image mirrors help avoid rate limits from public registries like Docker Hub by caching images locally. When you add a mirror, all image pulls from that registry are transparently redirected through the local cache.

## vkdr mirror list

List all configured container image mirrors.

```bash
vkdr mirror list
```

### Example

```bash
vkdr mirror list
```

## vkdr mirror add

Add a container image mirror for a specific registry.

```bash
vkdr mirror add --host=<host>
```

### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--host` | Hostname of the registry to mirror | (required) |

### Examples

Add a mirror for Docker Hub:

```bash
vkdr mirror add --host docker.io
```

Add a mirror for GitHub Container Registry:

```bash
vkdr mirror add --host ghcr.io
```

Add a mirror for Quay.io:

```bash
vkdr mirror add --host quay.io
```

## vkdr mirror remove

Remove a container image mirror.

```bash
vkdr mirror remove --host=<host>
```

### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--host` | Hostname of the registry mirror to remove | (required) |

### Example

```bash
vkdr mirror remove --host docker.io
```

## vkdr mirror explain

Explain mirror configuration and usage.

```bash
vkdr mirror explain
```

## Complete Examples

### Setting Up Mirrors for Common Registries

```bash
# Start cluster
vkdr infra up

# Add mirrors for popular registries
vkdr mirror add --host docker.io
vkdr mirror add --host ghcr.io
vkdr mirror add --host quay.io
vkdr mirror add --host gcr.io

# List configured mirrors
vkdr mirror list

# Now all pulls from these registries go through the local cache
```

### Avoiding Docker Hub Rate Limits

Docker Hub has rate limits for anonymous pulls. Using a mirror helps:

```bash
# Start cluster
vkdr infra up

# Add Docker Hub mirror
vkdr mirror add --host docker.io

# Pull images normally - they'll be cached locally
kubectl run nginx --image=nginx:latest

# Subsequent pulls use the local cache
```

## How Mirrors Work

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Pod requests   │     │  Local Mirror   │     │  Remote         │
│  image from     │────>│  Registry       │────>│  Registry       │
│  docker.io      │     │  (port 6000)    │     │  (docker.io)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                              │
                              v
                        ┌─────────────┐
                        │  Local      │
                        │  Cache      │
                        └─────────────┘
```

1. **First pull**: Image is fetched from remote registry and cached locally
2. **Subsequent pulls**: Image is served from local cache
3. **Transparent**: No changes needed to your deployments or image references

## Supported Registries

You can mirror any container registry:

| Registry | Host |
|----------|------|
| Docker Hub | `docker.io` |
| GitHub Container Registry | `ghcr.io` |
| Quay.io | `quay.io` |
| Google Container Registry | `gcr.io` |
| Amazon ECR Public | `public.ecr.aws` |
| Azure Container Registry | `*.azurecr.io` |

## Benefits

- **Avoid rate limits**: Docker Hub limits anonymous pulls to 100/6h
- **Faster pulls**: Cached images are served locally
- **Bandwidth savings**: Images are only downloaded once
- **Reliability**: Local cache works even if remote registry is slow/down
- **Air-gapped environments**: Pre-populate cache for offline use

## Configuration File

The mirror configuration is stored at:
```
~/.vkdr/scripts/.util/configs/mirror-registry.yaml
```

Example configuration:
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

Port numbers are automatically incremented for each new endpoint, starting from 6000.

## Important Notes

- Mirrors are started during `vkdr infra start` (or `vkdr infra up`)
- You need to restart the cluster after adding a new mirror
- The mirror process is transparent to users and applications
- Images not in the cache are pulled from the original registry and cached for future use
