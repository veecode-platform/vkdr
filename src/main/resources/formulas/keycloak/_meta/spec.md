# keycloak Formula Specification

Implementation details for Claude Code. For user documentation, see [docs.md](docs.md).

## Overview

Installs Keycloak identity and access management using the Keycloak Operator. Keycloak is deployed as a Custom Resource managed by the operator.

## Dependencies

- **PostgreSQL**: Required for Keycloak database (auto-installed if not present)
- **Ingress Controller**: For external access (nginx or kong)
- **Keycloak Operator**: Installed automatically on first install

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Keycloak Operator                         │
│                 namespace: keycloak                         │
│  - Watches Keycloak CRs                                     │
│  - Manages Keycloak pods and services                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 Keycloak CR: vkdr-keycloak                  │
│                   namespace: keycloak                       │
│  - spec.hostname.hostname: http://auth.localhost:8000      │
│  - spec.db: references keycloak-db-secret                  │
│  - spec.ingress: enabled with annotations                  │
└─────────────────────────────────────────────────────────────┘
           │                               │
           ▼                               ▼
┌──────────────────────┐      ┌──────────────────────────────┐
│   Bootstrap Secret   │      │      Database Secret         │
│ vkdr-keycloak-       │      │    keycloak-db-secret        │
│ bootstrap-admin-user │      │  (copied from postgres)      │
│ - username           │      │  - username                  │
│ - password           │      │  - password                  │
└──────────────────────┘      └──────────────────────────────┘
                                           │
                                           ▼
                              ┌──────────────────────────────┐
                              │   PostgreSQL (CloudNativePG) │
                              │      namespace: vkdr         │
                              │  - cluster: vkdr-pg-cluster  │
                              │  - database: keycloak        │
                              │  - user: keycloak            │
                              └──────────────────────────────┘
```

## Design Decisions

### Why Keycloak Operator (not Helm)

The Keycloak Operator provides:
- Declarative configuration via CRDs
- Automatic handling of upgrades and restarts
- Better integration with Kubernetes lifecycle
- Realm import via KeycloakRealmImport CRD

### Why Auto-Install PostgreSQL

Keycloak requires a database. Rather than fail if PostgreSQL isn't present, we automatically install it using `vkdr postgres install`. This provides a better developer experience.

### Secret Management

Three secrets are involved:
1. **Bootstrap Admin Secret** (`vkdr-keycloak-bootstrap-admin-user`): Initial admin credentials, created from CLI parameters
2. **Database Secret** (`keycloak-db-secret`): Copied from PostgreSQL role secret to keycloak namespace
3. **PostgreSQL Role Secret** (`vkdr-pg-cluster-role-keycloak`): Created by `vkdr postgres createdb`

### Why Operator is Not Removed

The remove command only deletes:
- Keycloak CR (server)
- Database and role
- Secrets

The operator is **kept** because:
- Other Keycloak instances might use it
- Reinstalling is faster with operator already present
- CRDs remain available

### Namespace Separation

- Keycloak server: `keycloak` namespace
- PostgreSQL: `vkdr` namespace (shared with other services)

## Key Files

| File | Purpose |
|------|---------|
| `install/formula.sh` | Install operator + Keycloak server |
| `remove/formula.sh` | Remove server + database (not operator) |
| `import/formula.sh` | Import realm via kcadm.sh |
| `export/formula.sh` | Export realm via kcadm.sh |
| `_shared/operators/keycloak/keycloak-operator.yml` | Operator deployment |
| `_shared/operators/keycloak/keycloak-server.yml` | Keycloak CR template |
| `_shared/operators/keycloak/*.k8s.keycloak.org-v1.yml` | CRDs |

## Parameters

### Install

| Parameter | Variable | Description |
|-----------|----------|-------------|
| `--domain` | `$1` | Base domain (default: localhost) |
| `--secure` | `$2` | Enable HTTPS (default: false) |
| `--user` | `$3` | Admin username (default: admin) |
| `--password` | `$4` | Admin password (default: admin) |

### Import/Export

| Parameter | Variable | Description |
|-----------|----------|-------------|
| `--file` | `$1` | Realm JSON file path |
| `--realm` | `$2` (export only) | Realm name to export |
| `--admin` | `$2/$3` | Admin password (or read from secret) |

## Functions

### install/formula.sh

| Function | Purpose |
|----------|---------|
| `configure` | Install operator if not present, copy server YAML to temp |
| `ensurePostgresDatabase` | Install postgres if needed, create keycloak database |
| `ensurePostgresSecret` | Copy credentials from postgres secret to keycloak namespace |
| `ensureAdminSecret` | Create bootstrap admin secret |
| `configDomain` | Set hostname in Keycloak CR, configure TLS if secure |
| `install` | Apply Keycloak CR |

### export/formula.sh

| Function | Purpose |
|----------|---------|
| `getSecret` | Get admin password from secret if not provided |
| `export` | Export realm, users, groups, clients, roles via kcadm.sh |

Export collects multiple resources and merges them into a single JSON file using `jq`.

## Integration with Other Services

### Kong OIDC

When Kong is installed with `--oidc`, it expects:
- Keycloak realm named `vkdr`
- OpenID Connect client named `kong-admin`

```bash
vkdr kong install --default-ic --oidc
vkdr keycloak install
# Manual: create vkdr realm and kong-admin client in Keycloak
```

### ACME/Let's Encrypt

If ACME ingress is detected, Keycloak:
- Does NOT set `spec.ingress.tlsSecret`
- Adds host to ACME ingress for certificate generation

## Known Limitations

1. **Import/Export Namespace**: Hardcoded to look for `keycloak-0` pod in `vkdr` namespace (inconsistent with install which uses `keycloak` namespace)
2. **Single Instance**: Only one Keycloak instance supported
3. **Operator Not Removed**: Must manually delete operator if needed
4. **No HA Mode**: Single replica deployment only

## Namespace Inconsistency (Bug)

```bash
# install/formula.sh
KEYCLOAK_NAMESPACE=keycloak

# import/formula.sh and export/formula.sh
KEYCLOAK_NAMESPACE=vkdr  # BUG: should be 'keycloak'
KEYCLOAK_POD_NAME=keycloak-0  # Pod naming depends on operator
```

This may cause import/export to fail if the pod is in the wrong namespace.

## Database Credentials

Hardcoded in install formula:
```bash
POSTGRES_DB_NAME="keycloak"
POSTGRES_USER="keycloak"
POSTGRES_PASSWORD="auth1234"
```

## Testing

Tests should verify:
1. Operator deployment is ready
2. Keycloak CR is created and reconciled
3. Database and secrets are created
4. Ingress is configured correctly
5. Admin console is accessible

## Updating

Uses Keycloak Operator installed from versioned manifest files. To update:
1. Check latest release at https://github.com/keycloak/keycloak-k8s-resources
2. Download updated operator YAML and CRDs
3. Update files in `_shared/operators/keycloak/`
4. Check release notes for CRD changes affecting Keycloak CR
5. Run tests

See `_meta/update.yaml` for automation config.

## Future Improvements

- [ ] Fix namespace inconsistency in import/export
- [ ] Add `--gateway` flag for Gateway API support
- [ ] Support multiple Keycloak instances
- [ ] Add `--ha` flag for high availability mode
- [ ] Make database credentials configurable
