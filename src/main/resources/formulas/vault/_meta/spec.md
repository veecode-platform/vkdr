# vault Formula Specification

Implementation details for Claude Code. For user documentation, see [docs.md](docs.md).

## Overview

Installs HashiCorp Vault for secrets management using the official Helm chart. Supports development mode (auto-unsealed) and production mode (requires init/unseal).

## Dependencies

- **Ingress Controller**: For external access (nginx, traefik, or kong)
- **No database required**: Vault uses integrated storage (Raft) by default

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Vault Server (vault-0)                   │
│                      namespace: vkdr                        │
│  Modes:                                                     │
│  - Dev: auto-unsealed, in-memory, root token set           │
│  - Prod: sealed on start, requires init + unseal           │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│   vault-keys     │ │  vault-server-ca │ │ vault-server-tls │
│   (Secret)       │ │    (Secret)      │ │    (Secret)      │
│ - unseal-key     │ │ - ca.crt         │ │ - tls.crt        │
│ - root-token     │ │                  │ │ - tls.key        │
└──────────────────┘ └──────────────────┘ └──────────────────┘
       ▲                     ▲                    ▲
       │                     │                    │
   vault init          generate-tls          generate-tls
```

## Design Decisions

### Why Two Modes (Dev vs Production)

**Dev Mode** (`--dev`):
- Auto-initialized and unsealed
- In-memory storage (data lost on restart)
- Known root token (configurable via `--dev-root-token`)
- Perfect for local development and testing

**Production Mode** (default):
- Sealed on startup
- Persistent storage via Raft
- Requires manual init and unseal
- Unseal keys stored in `vault-keys` secret

### Why Store Unseal Keys in Kubernetes Secret

For local development convenience. In production, unseal keys should be:
- Stored in a secure external location
- Split across multiple administrators
- Never stored in the same cluster as Vault

### TLS Mode

TLS can be enabled on Vault's internal listener (port 8200) for:
- Secure pod-to-pod communication
- Required when using Vault Agent Injector in strict mode
- Certificates generated via `vkdr vault generate-tls`

### Secrets Engines Auto-Enabled

On `vault init`, two secrets engines are automatically enabled:
- `secret/` - KV-v2 for general secrets
- `database/` - For dynamic database credentials

## Key Files

| File | Purpose |
|------|---------|
| `install/formula.sh` | Install Vault via Helm |
| `remove/formula.sh` | Remove Vault Helm release |
| `init/formula.sh` | Initialize and unseal Vault |
| `generate-tls/formula.sh` | Generate CA and server certificates |
| `_shared/values/vault.yaml` | Helm values for non-TLS mode |
| `_shared/values/vault-tls.yaml` | Helm values for TLS mode |

## Parameters

### Install

| Parameter | Variable | Description |
|-----------|----------|-------------|
| `--domain` | `$1` | Base domain (default: localhost) |
| `--secure` | `$2` | Enable HTTPS ingress (default: false) |
| `--dev` | `$3` | Dev mode (default: false) |
| `--dev-root-token` | `$4` | Root token for dev mode (default: root) |
| `--tls` | `$5` | Enable TLS on Vault listener (default: false) |

### Generate-TLS

| Parameter | Variable | Description |
|-----------|----------|-------------|
| `--cn` | `$1` | Certificate Common Name (default: vault) |
| `--days` | `$2` | Validity in days (default: 365) |
| `--save` | `$3` | Save to Kubernetes secrets (default: false) |
| `--force` | `$4` | Force regeneration (default: false) |

## Functions

### install/formula.sh

| Function | Purpose |
|----------|---------|
| `settings` | Select values file (TLS or non-TLS) |
| `configDomain` | Configure ingress host and TLS |
| `setDevMode` | Enable dev mode and set root token |
| `installVault` | Helm install |
| `postInstall` | Save dev token to secret |

### init/formula.sh

| Function | Purpose |
|----------|---------|
| `getVaultStatus` | Check if initialized/sealed/ready |
| `doInitVault` | Run `vault operator init`, save keys to secret |
| `doUnsealVault` | Run `vault operator unseal` |
| `doEnableEngines` | Enable kv-v2 and database engines |

### generate-tls/formula.sh

| Function | Purpose |
|----------|---------|
| `generateCA` | Generate CA key and certificate |
| `generateVaultCert` | Generate Vault server certificate with SANs |
| `createK8sSecrets` | Create `vault-server-ca` and `vault-server-tls` secrets |

## Certificate SANs

Generated certificates include these Subject Alternative Names:
```
DNS.1 = ${CN}              # e.g., vault
DNS.2 = vault
DNS.3 = vault.vkdr
DNS.4 = vault.vkdr.svc
DNS.5 = vault.vkdr.svc.cluster.local
DNS.6 = localhost
IP.1 = 127.0.0.1
```

## Certificate Storage

Certificates are stored in two locations:
1. **Local filesystem**: `$HOME/.vkdr/certs/vault/`
   - `ca.key`, `ca.crt` - CA keypair
   - `vault.key`, `vault.crt` - Server keypair
2. **Kubernetes secrets** (with `--save`):
   - `vault-server-ca` - CA certificate
   - `vault-server-tls` - Server TLS keypair

## Integration with Other Services

### External Secrets Operator (ESO)

```bash
vkdr vault install --dev
vkdr vault init  # if not dev mode
vkdr eso install
# ESO can now fetch secrets from Vault
```

### PostgreSQL Dynamic Credentials

```bash
vkdr vault install --dev
vkdr postgres install
vkdr postgres createdb -d myapp -u myuser --vault
# Vault manages rotating credentials for myapp database
```

## Vault Status States

The `init` command handles three states:

| Status | Meaning | Action |
|--------|---------|--------|
| `uninitialized` | Fresh Vault, never initialized | Run init → unseal → enable engines |
| `sealed` | Initialized but sealed | Run unseal → enable engines |
| `ready` | Initialized and unsealed | Only enable engines if missing |

## Known Limitations

1. **Single Instance**: Only one Vault pod (no HA mode)
2. **Unseal Keys in Cluster**: Not suitable for production security
3. **No Auto-Unseal**: Manual unseal required after pod restart in prod mode

## Updating

Uses latest `hashicorp/vault` chart version. No version pin - updates happen automatically on next install. Vault is stable but check release notes for breaking changes in values structure.

See `_meta/update.yaml` for automation config.

## Future Improvements

- [ ] Add `--gateway` flag for Gateway API support
- [ ] Support HA mode with multiple replicas
- [ ] Add auto-unseal via cloud KMS
