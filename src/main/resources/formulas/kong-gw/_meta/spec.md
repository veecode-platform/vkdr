# kong-gw Formula Specification

## Purpose

Install and manage Kong Gateway Operator as a Gateway API implementation in the VKDR cluster.

## Files

| File | Purpose |
|------|---------|
| `install/formula.sh` | Installs Kong Gateway Operator and creates default Gateway |
| `remove/formula.sh` | Removes Gateway and optionally the operator |
| `explain/formula.sh` | Displays documentation |
| `_meta/docs.md` | User documentation |
| `_meta/update.yaml` | Version tracking for automated updates |

## Dependencies

- Gateway API CRDs (installed automatically from kubernetes-sigs/gateway-api)
- Helm chart: `kong/kong-operator` from https://charts.konghq.com

## GatewayClass

Creates a GatewayClass named `kong` with controller `konghq.com/gateway-operator`.

## Namespace

All resources are created in `kong-system` namespace.

## Updating

This formula uses `helm-pinned` update type. To update:

1. Check for new versions: `helm search repo kong/kong-operator --versions`
2. Update `KGO_VERSION` in `install/formula.sh`
3. Update `version` in `_meta/update.yaml`
4. Run tests: `make test-formula formula=kong-gw`
