# eso Formula Specification

Simple formula. Inspect formula files directly for implementation details.

## Purpose

Installs External Secrets Operator (ESO) via Helm chart. Syncs secrets from external providers (Vault, AWS, etc.) to Kubernetes.

## Key Files

| File | Purpose |
|------|---------|
| `install/formula.sh` | Deploy ESO to vkdr namespace |
| `remove/formula.sh` | Remove ESO Helm release |

## Integration

Works with `vkdr vault` for fetching secrets from HashiCorp Vault.

```bash
vkdr vault install --dev
vkdr eso install
# Configure ClusterSecretStore and ExternalSecret CRDs
```

## Updating

Uses latest `external-secrets/external-secrets` chart version. No version pin - updates happen automatically. Tests will catch breaking changes.

See `_meta/update.yaml` for automation config.
