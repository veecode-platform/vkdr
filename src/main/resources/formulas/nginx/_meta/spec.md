# nginx Formula Specification

Simple formula. Inspect formula files directly for implementation details.

## Purpose

Installs NGINX Ingress Controller via Helm chart. For Kubernetes Ingress API support.

## Key Files

| File | Purpose |
|------|---------|
| `install/formula.sh` | Deploy nginx-ingress as LoadBalancer or NodePort |
| `remove/formula.sh` | Remove nginx-ingress Helm release |

## Features

- LoadBalancer mode (default)
- NodePort mode via `--nodeports` flag
- Default ingress controller via `--default-ic` flag

## Note

For Gateway API support, use `nginx-gw` formula instead.
