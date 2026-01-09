# infra Formula Specification

Implementation details for Claude Code. For user documentation, see [docs.md](docs.md).

## Overview

Manages the local Kubernetes development environment using k3d (k3s in Docker). Handles cluster lifecycle, registry mirrors for faster image pulls, and remote cluster exposure via Cloudflare tunnels.

## Dependencies

- **Docker**: Required for k3d to run (checked via `docker-tools.sh`)
- **k3d**: Kubernetes distribution (bundled with VKDR)
- **No Kubernetes required**: This formula creates the cluster

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Docker Engine                            │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              k3d Cluster: vkdr-local                   │ │
│  │                                                        │ │
│  │  ┌─────────────────┐  ┌─────────────────┐             │ │
│  │  │   Server Node   │  │   Agent Nodes   │             │ │
│  │  │   (control)     │  │   (--agents N)  │             │ │
│  │  └─────────────────┘  └─────────────────┘             │ │
│  │                                                        │ │
│  │  ┌─────────────────┐                                  │ │
│  │  │   LoadBalancer  │  Ports: 8000→80, 8001→443       │ │
│  │  └─────────────────┘  NodePorts: 32000-32099→30000   │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐                 │
│  │ k3d-docker-io    │  │ k3d-registry-k8s │                 │
│  │ (mirror)         │  │ (mirror)         │                 │
│  │ Port: 6001       │  │ Port: 6002       │                 │
│  │ → registry-1.    │  │ → registry.k8s.io│                 │
│  │   docker.io      │  │                  │                 │
│  └──────────────────┘  └──────────────────┘                 │
└─────────────────────────────────────────────────────────────┘
```

## Design Decisions

### Why k3d (not Kind, Minikube)

k3d provides:
- Fast cluster startup (seconds, not minutes)
- Built-in registry mirror support
- LoadBalancer support via servicelb
- Multiple node agents for realistic testing
- Simple port mapping to host

### Why Registry Mirrors

Pulling images from Docker Hub is slow and rate-limited. Registry mirrors:
- Cache images locally in persistent Docker volumes
- Survive cluster restarts (volumes are not deleted)
- Eliminate rate limiting issues
- Faster subsequent pulls

### Mirror Configuration

Mirrors are configured in `~/.vkdr/configs/mirror-registry.yaml`:

```yaml
mirrors:
  "docker.io":
    endpoint:
      - http://host.k3d.internal:6001
  "registry.k8s.io":
    endpoint:
      - http://host.k3d.internal:6002
  "ghcr.io":
    endpoint:
      - http://host.k3d.internal:6003
```

The default config is copied to `~/.vkdr/configs/` on first `vkdr init` and preserved on subsequent runs. Users can add/remove mirrors with `vkdr mirror add/remove` commands.

### Traefik Ingress

By default, k3d includes Traefik ingress controller. VKDR disables it by default (`--traefik false`) because:
- VKDR provides `nginx install` and `kong install` as ingress options
- Avoids port conflicts
- User can enable with `--traefik true` if desired

### CoreDNS Patching

After cluster start, CoreDNS is patched to resolve `*.localdomain` to the cluster. This enables:
- OIDC flows where pods need to reach auth server via public hostname
- Local domain resolution within the cluster

## Key Files

| File | Purpose |
|------|---------|
| `start/formula.sh` | Create cluster with mirrors and port mappings |
| `stop/formula.sh` | Delete cluster, optionally delete registries |
| `expose/formula.sh` | Create Cloudflare tunnel for remote access |
| `createtoken/formula.sh` | Generate service account token |
| `getca/formula.sh` | Extract cluster CA certificate |
| `~/.vkdr/configs/mirror-registry.yaml` | User's mirror registry configuration |
| `_shared/configs/rewrite-coredns.yaml` | CoreDNS localdomain patch |
| `_shared/lib/docker-tools.sh` | Docker engine check utilities |

## Parameters

### Start

| Parameter | Variable | Description |
|-----------|----------|-------------|
| `--traefik` | `$1` | Enable Traefik ingress (default: false) |
| `--http` | `$2` | Host HTTP port (default: 8000) |
| `--https` | `$3` | Host HTTPS port (default: 8001) |
| `--nodeports` | `$4` | Number of NodePorts (default: 0) |
| `--api-port` | `$5` | K8s API port (default: random) |
| `--agents` | `$6` | Number of agent nodes (default: 0) |
| `--volumes` | `$7` | Host volumes to mount (comma-separated) |
| `--nodeport-base` | `$8` | Host NodePort base (default: 32000) |

### Stop

| Parameter | Variable | Description |
|-----------|----------|-------------|
| `--delete-registry` | `$1` | Delete registry containers (default: false) |

### Expose

| Parameter | Variable | Description |
|-----------|----------|-------------|
| `--off` | `$1` | Terminate tunnel (default: false) |

## Functions

### start/formula.sh

| Function | Purpose |
|----------|---------|
| `startMirrors` | Create k3d registry containers for each mirror |
| `startRegistry` | Create single registry with proxy-remote-url |
| `configureCluster` | Build k3d flags for ports, traefik, agents |
| `parseVolumes` | Convert comma-separated volumes to --volume flags |
| `startCluster` | Run k3d cluster create with all options |
| `postStart` | Patch CoreDNS for localdomain resolution |

### stop/formula.sh

| Function | Purpose |
|----------|---------|
| `stopCluster` | Delete cluster, optionally delete all mirrors |

### expose/formula.sh

| Function | Purpose |
|----------|---------|
| `createServiceAccount` | Create superadmin SA with cluster-admin |
| `startTunnel` | Run cloudflared pod for tunnel |
| `getTunnelURLFromLog` | Poll pod logs for .trycloudflare.com URL |
| `getCAFromDomain` | Extract TLS CA from tunnel endpoint |
| `generateSAKubeConfig` | Create kubeconfig for remote access |

## Port Mapping

```
Host Port    → Container Port  → Service
─────────────────────────────────────────
8000         → 80              → Ingress HTTP
8001         → 443             → Ingress HTTPS
32000-32099  → 30000-30099     → NodePorts (if enabled)
6001         → 5000            → Docker Hub mirror
6002         → 5000            → registry.k8s.io mirror
```

## Expose Feature

The expose command creates a Cloudflare Tunnel for remote access:

1. Creates `vkdr-expose` namespace
2. Deploys `cloudflare/cloudflared` pod with `tunnel --url` mode
3. Extracts public URL from pod logs
4. Creates kubeconfig at `~/.vkdr/tmp/kconfig` with:
   - Tunnel URL as server
   - Service account token for authentication
   - TLS CA from tunnel endpoint

Use case: Share local cluster with teammates, CI systems, or mobile testing.

## Volume Mounting

Volumes can be mounted from host to cluster nodes:

```bash
vkdr infra start --volumes "/data/shared:/mnt/data,/config:/etc/config"
```

Each volume is added as `--volume <path>@server:0` to k3d.

## Known Limitations

1. **Stop Not Idempotent**: Error message if cluster not running (but continues)
2. **Single Cluster**: Only one `vkdr-local` cluster supported
3. **Expose Requires Internet**: Cloudflare tunnel needs outbound access

## Stop Idempotency Issue

```bash
stopCluster() {
  if ${VKDR_K3D} cluster list | grep -q "vkdr-local"; then
    ${VKDR_K3D} cluster delete vkdr-local
  else
    error "Cluster vkdr-local not running..."  # Shows error but doesn't fail
  fi
  ...
}
```

The error message is misleading for idempotent operations (e.g., CI cleanup).

## Future Improvements

- [ ] Fix stop idempotency (info instead of error)
- [ ] Support multiple clusters
- [ ] Add `--registry` flag to disable mirrors
- [ ] Add `--memory` and `--cpu` flags for resource limits
- [ ] Add `--image` flag to customize k3s image version
