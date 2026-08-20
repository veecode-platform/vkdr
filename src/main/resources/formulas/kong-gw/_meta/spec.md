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
2. Update `KGO_CHART_VERSION` and `KGO_IMAGE_TAG` in `install/formula.sh`
   (the chart's `appVersion` is the operator release the chart was cut for; the
   image tag may run ahead of it)
3. Update `version` in `_meta/update.yaml`
4. Check the chart's Gateway API dependency version in `Chart.yaml`. If it moved past
   the vendored bundle, vendor the new one and update `GWAPI_CRDS_YAML` in both this
   formula and `nginx-gw`
5. Run tests: `make test-formula formula=kong-gw`

### CRDs

Per Kong's [upgrade docs](https://developer.konghq.com/operator/dataplanes/upgrade/operator/),
Helm installs CRDs on first install but never updates them. The chart splits them up:

| Subchart | Contents | How vkdr handles it |
| --- | --- | --- |
| `ko-crds` | Kong operator CRDs, as templates | Left to the chart - templated CRDs *are* upgraded |
| `gwapi-standard-crds` | Gateway API CRDs, as `crds/` (install-only) | Disabled; installed from `_shared/operators/gateway-api/` |
| `gwapi-experimental-crds` | Experimental Gateway API CRDs | Disabled by the chart default |

Gateway API CRDs are installed from the pinned shared copy so that a `kong-gw` bump
actually updates them, and so `nginx-gw` and `kong-gw` cannot fight over the
`safe-upgrades` ValidatingAdmissionPolicy that the bundle contains - Helm cannot adopt
an object it did not create, which used to break installing `kong-gw` after `nginx-gw`.
