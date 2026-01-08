# nginx-gw Formula Specification

Implementation details for Claude Code. For user documentation, see [docs.md](docs.md).

## Overview

Installs NGINX Gateway Fabric - a Gateway API implementation using NGINX as the data plane.

## Dependencies

- **Gateway API CRDs**: Installed via kustomize from nginx-gateway-fabric repo
- **NGINX Gateway Fabric Helm Chart**: `oci://ghcr.io/nginx/charts/nginx-gateway-fabric`
- **No ingress controller required**: This is a separate system from nginx-ingress

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GatewayClass: nginx                      │
│            (created by helm chart automatically)            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Gateway: nginx                         │
│                  namespace: nginx-gateway                   │
│  - HTTP listener (port 80)                                  │
│  - HTTPS listener (port 443, TLS terminate)                 │
│  - allowedRoutes.namespaces.from: All                       │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌──────────────────────┐         ┌──────────────────────┐
│  NginxProxy (optional)│         │   TLS Secret         │
│  For NodePort config  │         │   nginx-gateway-tls  │
└──────────────────────┘         └──────────────────────┘
```

## Design Decisions

### Why `allowedRoutes.namespaces.from: All`

By default, Gateway listeners only accept HTTPRoutes from the same namespace. Since services (whoami, kong, etc.) are deployed in their own namespaces, we must allow routes from all namespaces.

### Why NginxProxy for NodePort (not annotations)

Gateway API resources don't use annotations like Ingress. NGINX Gateway Fabric provides the `NginxProxy` CRD to configure the underlying NGINX service:

```yaml
apiVersion: gateway.nginx.org/v1alpha2
kind: NginxProxy
metadata:
  name: nginx-proxy-config
spec:
  kubernetes:
    service:
      type: NodePort
      nodePorts:
      - port: 30000
        listenerPort: 80
```

The Gateway references this via `infrastructure.parametersRef`.

### Why Self-Signed TLS Certificate

HTTPS listener with `tls.mode: Terminate` requires a certificate. We generate a self-signed cert with SANs for localhost development:
- `localhost`, `*.localhost`
- `localdomain`, `*.localdomain`

The certificate subject is intentionally humorous for easy identification during debugging.

### Why Control Plane Lifecycle Optimization

- **Install**: Checks if helm release exists before reinstalling (allows Gateway updates without full reinstall)
- **Remove**: Only removes Gateway by default (fast iteration), `--all` for full cleanup
- **TLS Secret**: Preserved on default remove, deleted with `--all` (namespace deletion)

## Key Files

| File | Purpose |
|------|---------|
| `install/formula.sh` | Main install logic |
| `remove/formula.sh` | Remove logic with idempotency |
| `_meta/docs.md` | User-facing documentation |
| `_meta/spec.md` | This file - implementation details |

## Parameters

### Install

| Parameter | Variable | Description |
|-----------|----------|-------------|
| `--node-ports` | `$1` | NodePort values (e.g., `30000,30001` or `*` for defaults) |

### Remove

| Parameter | Variable | Description |
|-----------|----------|-------------|
| `--delete-fabric` / `--all` | `$1` | If "true", removes control plane and namespace |

## Functions

### install/formula.sh

| Function | Purpose |
|----------|---------|
| `installGatewayAPICRDs` | Install Gateway API CRDs via kustomize |
| `createSelfSignedCert` | Generate TLS cert if not exists |
| `installControlPlane` | Helm install nginx-gateway-fabric |
| `isControlPlaneInstalled` | Check if helm release exists |
| `createGatewayLB` | Create Gateway with LoadBalancer service |
| `createGatewayNP` | Create Gateway + NginxProxy for NodePort |

### remove/formula.sh

| Function | Purpose |
|----------|---------|
| `removeGateway` | Delete Gateway resource |
| `removeNginxProxy` | Delete NginxProxy resource |
| `removeControlPlane` | Helm uninstall (if exists) |
| `removeNamespace` | Delete entire nginx-gateway namespace |

## Integration with Other Formulas

Formulas can use `--gateway nginx` to route via Gateway API instead of Ingress:

```bash
# In formula that supports Gateway API
source "$SHARED_DIR/lib/gateway-tools.sh"

if [ -n "$GATEWAY_CLASS" ]; then
  configureGatewayRoute "$VALUES_FILE" "$GATEWAY_CLASS" "$HOSTNAME" "$SERVICE" "$PORT" "$NAMESPACE"
fi
```

The `gateway-tools.sh` library:
1. Checks if GatewayClass exists
2. Finds Gateway by class name
3. Disables Ingress in helm values
4. Adds HTTPRoute via `extraDeploy`

## Known Limitations

1. **Single Gateway**: Only creates one Gateway named `nginx`. Multiple Gateways not supported.
2. **TLS Certificate**: Self-signed only. No Let's Encrypt / cert-manager integration.
3. **Gateway API CRDs**: Not removed on uninstall (shared resource, might be used by other controllers).

## Updating

Version is pinned in `install/formula.sh`. To update:
1. Check latest release at https://github.com/nginx/nginx-gateway-fabric/releases
2. Update `NGF_VERSION` in formula
3. Verify CRD kustomize URL still works with new version
4. Run tests - Gateway API CRDs may have breaking changes

See `_meta/update.yaml` for automation config.

## Testing

Tests assume only cluster is running (`vkdr infra up`). They verify:
1. Command succeeds
2. Controller pods are ready
3. Gateway, GatewayClass, and service exist
4. Remove cleans up resources

See `src/test/bats/formulas/nginx-gw/` for test files.
