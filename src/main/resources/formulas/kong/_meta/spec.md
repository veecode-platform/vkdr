# kong Formula Specification

Implementation details for Claude Code. For user documentation, see [docs.md](docs.md).

## Overview

Installs Kong Gateway as an API gateway and ingress controller using the official Helm chart. Supports OSS and Enterprise editions, DBless and Standard (PostgreSQL) modes.

## Dependencies

- **PostgreSQL**: Required for `standard` mode (auto-installed if not present)
- **Keycloak**: Optional for OIDC authentication on Admin UI
- **Ingress Controller**: Not required (Kong IS the ingress controller)

## Architecture

```pre
┌─────────────────────────────────────────────────────────────┐
│                      Kong Gateway                           │
│                     namespace: vkdr                         │
│  Modes:                                                     │
│  - dbless: declarative config, no database                  │
│  - standard: PostgreSQL database, dynamic config            │
└─────────────────────────────────────────────────────────────┘
           │                               │
           ▼                               ▼
┌──────────────────────────┐   ┌──────────────────────────────┐
│  Enterprise Secrets      │   │     Database (standard)      │
│  (if --enterprise)       │   │                              │
│  - kong-enterprise-      │   │  PostgreSQL (CloudNativePG)  │
│    license               │   │  - database: kong            │
│  - kong-enterprise-      │   │  - user: kong                │
│    superuser-password    │   │  - secret: vkdr-pg-cluster-  │
│  - kong-session-config   │   │            role-kong         │
│  - kong-admin-oidc       │   │                              │
└──────────────────────────┘   └──────────────────────────────┘
```

## Design Decisions

### Why Two Modes (DBless vs Standard)

**DBless Mode** (default):

- No database required
- Configuration via declarative YAML/Kubernetes CRDs
- Simpler, faster startup
- Best for: development, GitOps workflows

**Standard Mode**:

- PostgreSQL database required
- Dynamic configuration via Admin API
- Supports clustering and state persistence
- Best for: production, complex routing

### Why Auto-Install PostgreSQL

Like Keycloak, Kong in standard mode requires PostgreSQL. Rather than fail, we auto-install using `vkdr postgres install` and create the `kong` database.

### Enterprise Secrets

Kong Enterprise requires multiple secrets:

1. **License**: `kong-enterprise-license` - License JSON or empty
2. **Admin Password**: `kong-enterprise-superuser-password` - For RBAC
3. **Session Config**: `kong-session-config` - Cookie settings for Admin UI
4. **OIDC Config**: `kong-admin-oidc` - Keycloak integration settings

### Distroless Images

Distroless Kong images (`veecode/kong:X.Y-distroless`,
`kong/kong-gateway:X.Y-distroless`) contain no shell and no coreutils. Two
chart constructs reuse `.Values.image` and break on them:

- **`clear-stale-pid`** (`templates/deployment.yaml:102-121`): runs
  `rm -vrf $(KONG_PREFIX)/pids`. Chart >= 3.4.1 accepts
  `deployment.kong.initContainers.clearStalePid.image`, so it is pointed at
  `busybox` and keeps the chart's own default `command`. `$(KONG_PREFIX)` is
  Kubernetes env expansion in the container spec (from `env.prefix`, injected by
  the `kong.env` helper), not shell expansion - it must stay `$(...)`, never
  `${...}`.
- **`wait-for-db`** (helper `kong.wait-for-db`, rendered by
  `templates/deployment.yaml:125` when `env.database != "off"`): runs
  `/bin/bash -c "... until kong start; ..."` with `.Values.image` hardcoded and
  no override hook. `waitImage.repository` is read only by the
  `kong.wait-for-postgres` helper, which needs the `postgresql` subchart -
  never enabled here, since vkdr always uses an external CNPG database. The only
  option is `waitImage.enabled: false`; Kong then retries the database
  connection itself, at the cost of a few pod restarts while PostgreSQL boots.

Both live in `delta-kong-distroless.yaml`, merged by `configDistroless()`. The
overlay is applied when `--distroless` is passed **or** when the image name/tag
contains `distroless` (`isDistroless()`), so the official tags need no flag. It
is harmless in `dbless` mode, where `wait-for-db` is not rendered anyway.

### ACME Plugin

When `--acme` is enabled:

- Global KongPlugin resource for ACME is created
- A "dummy" ingress is created to trigger certificate generation
- Works with Let's Encrypt staging or production

## Key Files

| File | Purpose |
|------|---------|
| `install/formula.sh` | Main install logic with many configuration options |
| `remove/formula.sh` | Remove Kong Helm release |
| `_meta/values/kong-dbless.yaml` | Helm values for DBless mode |
| `_meta/values/kong-standard.yaml` | Helm values for Standard mode |
| `_meta/values/delta-kong-enterprise.yaml` | Enterprise overlay values |
| `_meta/values/delta-kong-distroless.yaml` | Distroless overlay values |
| `_meta/values/delta-kong-std-dbsecrets.yaml` | External database config |
| `_meta/values/acme-*.yaml` | ACME plugin configurations |
| `_meta/values/admin_gui_auth_conf` | OIDC configuration template |

## Parameters

### Install (19 parameters!)

| Parameter | Variable | Description |
|-----------|----------|-------------|
| `--domain` | `$1` | Base domain (default: localhost) |
| `--secure` | `$2` | Enable HTTPS (default: false) |
| `--mode` | `$3` | dbless, standard, or hybrid |
| `--enterprise` | `$4` | Enable enterprise features |
| `--license` | `$5` | License file path |
| `--image` | `$6` | Custom image name |
| `--tag` | `$7` | Custom image tag |
| `--admin` | `$8` | Admin password |
| `--api` | `$9` | Expose api.DOMAIN ingress |
| `--default-ic` | `$10` | Make default ingress controller |
| `--use-nodeport` | `$11` | Use NodePort instead of LoadBalancer |
| `--oidc` | `$12` | Enable Admin OIDC |
| `--log-level` | `$13` | Kong log level |
| `--acme` | `$14` | Enable ACME plugin |
| `--acme-server` | `$15` | staging or production |
| `--proxy-tls-secret` | `$16` | Default proxy TLS secret |
| `--env` | `$17` | JSON of extra env vars |
| `--label` | `$18` | JSON of extra labels |
| `--distroless` | `$19` | Adapt values for distroless images |

## Functions

### install/formula.sh

| Function | Purpose |
|----------|---------|
| `settingKong` | Select values file, merge enterprise overlay |
| `isDistroless` | Tell whether the distroless overlay applies |
| `configDistroless` | Merge distroless overlay |
| `ensurePostgresDatabase` | Auto-install postgres for standard mode |
| `createKongLicenseSecret` | Create license secret for enterprise |
| `createKongAdminSecret` | Create admin password secret |
| `createKongSessionConfigSecret` | Create session cookie config |
| `configDomain` | Set manager.DOMAIN URLs and TLS |
| `configApiDomain` | Set api.DOMAIN proxy ingress |
| `configUseNodePort` | Switch to NodePort service type |
| `configDefaultIngressController` | Add default ingress class annotation |
| `configAdminOIDC` | Configure Keycloak OIDC integration |
| `configProxyTLSSecret` | Mount custom TLS secret for proxy |
| `envKong` | Merge custom environment variables |
| `configLabels` | Apply custom labels |
| `enableACME` | Deploy ACME plugin and dummy ingress |

## Values File Selection

```pre
Mode + Enterprise → Values File
─────────────────────────────────
dbless + false    → kong-dbless.yaml
dbless + true     → kong-dbless.yaml + delta-kong-enterprise.yaml
standard + false  → kong-standard.yaml + delta-kong-std-dbsecrets.yaml
standard + true   → kong-standard.yaml + delta-kong-enterprise.yaml + delta-kong-std-dbsecrets.yaml

Any of the above + distroless → ... + delta-kong-distroless.yaml
```

## OIDC Integration

When `--oidc` is enabled, Kong Admin UI uses Keycloak for authentication:

1. Expects Keycloak at `auth.DOMAIN`
2. Expects realm `vkdr` with client `kong-admin`
3. Creates `kong-admin-oidc` secret from template
4. Template in `_meta/values/admin_gui_auth_conf`

## Known Limitations

1. **Hybrid Mode**: Not implemented (`error "hybrid not yet implemented"`)
2. **Remove Not Idempotent**: `helm delete` fails if not installed
3. **Many Parameters**: 19 positional parameters is unwieldy
4. **Database Credentials Hardcoded**: `kong/kong1234`

## Remove Idempotency (Bug)

```bash
removeKong() {
  $VKDR_HELM delete kong -n $KONG_NAMESPACE  # Fails if not installed
}
```

## Updating

Uses latest `kong/kong` chart version. No version pin - updates happen automatically on next install. Kong releases frequently, so tests are important to catch breaking changes in values files.

See `_meta/update.yaml` for automation config.

## Future Improvements

- [ ] Fix remove idempotency
- [ ] Implement hybrid mode
- [ ] Add `--gateway` flag for Gateway API support (Kong also supports Gateway API)
- [ ] Clean up secrets on remove
- [ ] Make database credentials configurable
