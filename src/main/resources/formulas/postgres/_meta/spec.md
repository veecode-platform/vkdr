# postgres Formula Specification

Implementation details for Claude Code. For user documentation, see [docs.md](docs.md).

## Overview

Installs PostgreSQL using the CloudNative-PG operator. Manages databases and roles declaratively via Kubernetes CRDs with optional Vault integration for dynamic credentials.

## Dependencies

- **CloudNative-PG Operator**: Auto-installed on first `postgres install`
- **Vault**: Optional for dynamic credential rotation via `--vault` flag

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│               CloudNative-PG Operator                       │
│                 namespace: cnpg-system                      │
│  - Watches Cluster, Database, and other CRDs                │
│  - Manages PostgreSQL pods and replication                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Cluster: vkdr-pg-cluster                       │
│                   namespace: vkdr                           │
│  - instances: 1 (single node)                               │
│  - storage: 512Mi (local-path)                              │
│  - managed.roles: declarative user management               │
└─────────────────────────────────────────────────────────────┘
           │                    │                    │
           ▼                    ▼                    ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│  Superuser       │ │  Database CRD    │ │   Role Secret    │
│  Secret          │ │                  │ │                  │
│ vkdr-pg-cluster- │ │ vkdr-pg-cluster- │ │ vkdr-pg-cluster- │
│ superuser        │ │ {dbname}         │ │ role-{user}      │
│ - username: app  │ │ - owner: {user}  │ │ - username       │
│ - password       │ │                  │ │ - password       │
└──────────────────┘ └──────────────────┘ └──────────────────┘
```

## Design Decisions

### Why CloudNative-PG Operator (not Helm Chart)

Previous versions used the Bitnami PostgreSQL Helm chart. CloudNative-PG provides:
- Declarative database and role management via CRDs
- Automatic failover and recovery
- Built-in backup/restore capabilities
- Better Kubernetes-native lifecycle management

### Why Declarative Role Management

Roles (users) are managed via the Cluster CRD's `spec.managed.roles` field:
- Secrets are auto-reloaded when labeled with `cnpg.io/reload=true`
- Role state is managed declaratively (`ensure: present/absent`)
- No need for SQL scripts or manual intervention

### Vault Integration

When `--vault` is used in createdb:
1. Role is created as a Vault static role
2. Vault manages password rotation automatically
3. Rotation schedule is configurable (default: hourly)

### Database Safety

CloudNative-PG does NOT auto-drop databases when CR is deleted. The `dropdb` command:
1. Executes `DROP DATABASE` via psql on primary pod
2. Deletes the Database CR
3. Removes role from `managed.roles`
4. Cleans up secrets

## Key Files

| File | Purpose |
|------|---------|
| `install/formula.sh` | Install operator + create cluster |
| `remove/formula.sh` | Remove cluster (keeps operator) |
| `createdb/formula.sh` | Create database + role (8 parameters) |
| `dropdb/formula.sh` | Drop database + role + secrets |
| `_shared/operators/cnpg-1.27.0.yaml` | CloudNative-PG operator manifest |
| `_shared/lib/vault-tools.sh` | Vault integration helpers |

## Parameters

### Install

| Parameter | Variable | Description |
|-----------|----------|-------------|
| `--admin` | `$1` | Admin password (default: vkdr1234) |
| `--wait` | `$2` | Wait for cluster ready (default: true) |

### Createdb

| Parameter | Variable | Description |
|-----------|----------|-------------|
| `-d, --database` | `$1` | Database name (required) |
| `--admin` | `$2` | Admin password (for Vault connection) |
| `-u, --user` | `$3` | Database owner username |
| `-p, --password` | `$4` | User password |
| `--store` | `$5` | Store secret (deprecated) |
| `--drop` | `$6` | Drop existing database first |
| `--vault` | `$7` | Use Vault for credential rotation |
| `--vault-rotation` | `$8` | Rotation schedule (default: "0 * * * *") |

### Remove

| Parameter | Variable | Description |
|-----------|----------|-------------|
| `--delete-storage` | `$1` | Delete PVCs and superuser secret |

### Dropdb

| Parameter | Variable | Description |
|-----------|----------|-------------|
| `-d, --database` | `$1` | Database name to drop |
| `-u, --user` | `$2` | User/role to remove |

## Functions

### install/formula.sh

| Function | Purpose |
|----------|---------|
| `install` | Deploy operator if needed, create superuser secret |
| `createCluster` | Apply Cluster CRD with resource limits |
| `waitForCluster` | Poll until readyInstances == instances |

### createdb/formula.sh

| Function | Purpose |
|----------|---------|
| `createDB` | Apply Database CRD |
| `createDatabaseRole` | Dispatch to Vault or operator-managed role |
| `createVaultManagedRole` | Configure Vault database/config and static-roles |
| `createDatabaseManagedRole` | Create secret + patch Cluster with role |
| `patchClusterWithRole` | JSON patch to add/update managed role |

### dropdb/formula.sh

| Function | Purpose |
|----------|---------|
| `dropDatabaseFromPostgres` | Execute DROP DATABASE via psql |
| `dropDB` | Delete Database CR, role, and secrets |
| `deleteRole` | Set role to `absent`, then remove from cluster |

## Cluster Configuration

Default cluster settings optimized for local development:

```yaml
spec:
  instances: 1
  postgresql:
    parameters:
      max_connections: "50"
      shared_buffers: "64MB"
      work_mem: "4MB"
      maintenance_work_mem: "32MB"
      effective_cache_size: "128MB"
  resources:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  storage:
    size: 512Mi
    storageClass: local-path
```

## Integration with Other Services

### Keycloak

```bash
vkdr postgres install
vkdr keycloak install  # Auto-creates keycloak database
```

Keycloak formula calls `vkdr postgres createdb -d keycloak -u keycloak -p auth1234`.

### Kong (Standard Mode)

```bash
vkdr postgres install
vkdr kong install --mode standard  # Auto-creates kong database
```

### Vault Dynamic Credentials

```bash
vkdr vault install --dev
vkdr postgres install
vkdr postgres createdb -d myapp -u myuser --vault
# Vault now manages password rotation for myuser
```

## Secret Naming Convention

| Secret | Purpose |
|--------|---------|
| `vkdr-pg-cluster-superuser` | Admin credentials (username: app) |
| `vkdr-pg-cluster-role-{user}` | Per-user credentials (created by createdb) |

## Known Limitations

1. **Single Instance**: No HA mode, only one PostgreSQL pod
2. **No Backup Configuration**: Backup/restore not exposed via CLI
3. **Remove Not Idempotent**: `kubectl delete cluster` fails if not present
4. **Hardcoded Cluster Name**: Always `vkdr-pg-cluster`

## Remove Idempotency (Bug)

```bash
remove() {
  kubectl delete cluster "$POSTGRES_CLUSTER_NAME" -n "$POSTGRES_NAMESPACE"  # Fails if not present
  ...
}
```

Should use `--ignore-not-found`.

## Future Improvements

- [ ] Fix remove idempotency
- [ ] Add HA mode support (`--replicas` flag)
- [ ] Expose backup/restore configuration
- [ ] Add `--gateway` flag for Gateway API support (expose pgAdmin)
- [ ] Make cluster name configurable
