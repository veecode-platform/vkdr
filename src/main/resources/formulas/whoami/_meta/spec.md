# whoami Formula Specification

Simple formula. Inspect formula files directly for implementation details.

## Purpose

Deploys the whoami test service via Helm chart. Useful for testing ingress configuration and connectivity.

## Key Files

| File | Purpose |
|------|---------|
| `install/formula.sh` | Deploy whoami with Ingress or Gateway API |
| `remove/formula.sh` | Remove whoami Helm release |
| `_meta/values/whoami.yaml` | Helm values template |

## Features

- Supports both Ingress and Gateway API (`--gateway` flag)
- Custom labels via `--label` flag
- TLS/ACME integration via `--secure` flag

## Updating

Uses `cowboysysop/whoami` Helm chart with pinned version. To update:
1. Check latest version at the Helm repo
2. Update `--version` in `install/formula.sh`
3. Review chart changelog for values changes
4. Run tests

See `_meta/update.yaml` for automation config.
