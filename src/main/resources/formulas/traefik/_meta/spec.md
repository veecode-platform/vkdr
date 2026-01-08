# traefik Formula Specification

Simple formula. Inspect formula files directly for implementation details.

## Purpose

Installs Traefik Ingress Controller via Helm chart. Alternative to nginx for Ingress API support.

## Key Files

| File | Purpose |
|------|---------|
| `install/formula.sh` | Deploy traefik as LoadBalancer or NodePort |
| `remove/formula.sh` | Remove traefik Helm release |
| `_shared/values/traefik-common.yaml` | Helm values template |

## Features

- LoadBalancer mode (default)
- NodePort mode via `--nodeports` flag
- Default ingress controller via `--default-ic` flag
- Dashboard exposed at `traefik-ui.{domain}`

## Updating

Uses latest `traefik/traefik` chart version. No version pin - updates happen automatically on next install. Tests will catch breaking changes in chart values.

See `_meta/update.yaml` for automation config.
