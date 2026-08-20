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
Its `parametersRef` always points at the `kong-config` GatewayConfiguration.

## Data plane image

The data plane image is pinned by the formula, like every other vkdr formula:

| Variable | Default |
| --- | --- |
| `VKDR_ENV_KONG_GW_IMAGE_NAME` (`--image`) | `kong/kong-gateway` |
| `VKDR_ENV_KONG_GW_IMAGE_TAG` (`--tag`) | `3.14` |
| `VKDR_ENV_KONG_GW_PROFILE` (`--profile`) | `default` |

### Profiles

`resolveProfile` in `install/formula.sh` owns this table; the enum in
`VkdrKongGwInstallCommand` only validates the accepted values. Keep both in sync with
`_meta/docs.md`.

| Profile | Image | Tag |
| --- | --- | --- |
| `default` | (unset - formula default applies) | (unset) |
| `kong` | `kong/kong-gateway` | `3.15.0.4` |
| `kong-distroless` | `kong/kong-gateway` | `3.15-distroless` |
| `oss` | `kong` | `3.9.3` |
| `apip` | `veecode/kong` | `3.10.0-veecode.10` |
| `apip-distroless` | `veecode/kong` | `3.10.0-veecode.10-distroless` |

Resolution order is per field: explicit `--image`/`--tag`, then the profile, then the
formula default. `--image`/`--tag` therefore default to empty in the Java command - that
is how the formula tells "user asked for this" from "nobody set it".

Note the `kong` profiles are 3.15, which requires a license to keep serving traffic;
`default` stays on 3.14 deliberately.

`3.14` is the last release whose enterprise image keeps serving traffic without a
license, which is why it is the default rather than a newer tag. Passing `--image kong`
selects the OSS image instead, and any tag may carry the `-distroless` suffix.

Set via the GatewayConfiguration, which is the documented path when the data plane is
owned by a Gateway - see
[set the DataPlane image](https://developer.konghq.com/operator/dataplanes/how-to/set-dataplane-image/).
A standalone `DataPlane` resource is *not* needed: `spec.dataPlaneOptions.deployment.podTemplateSpec`
takes the same `PodTemplateSpec`, and the container to patch must be named `proxy`.

`gateway-operator.konghq.com/v2beta1` is current, not dated: with chart 1.3.1 the
GatewayConfiguration CRD serves `v1beta1` and `v2beta1`, and `v2beta1` is the storage
version. `DataPlane` is still only `v1beta1`, which is why the docs example uses it.

### Why the GatewayConfiguration is unconditional

Earlier versions created it only in NodePort mode, so LoadBalancer installs silently
inherited whatever image the operator defaulted to. It is now always applied - the two
modes differ only by the `network` block, rendered by `gatewayNetworkBlock`. It is also
always named `kong-config`; the NodePort path used to name it `kong-nodeport-config`,
which `remove` never deleted.

## Ingress support

The control plane the operator creates is Kong Ingress Controller, so one data plane
serves Gateway API and Ingress at the same time. Per
[handle ingress](https://developer.konghq.com/operator/dataplanes/how-to/handle-ingress/),
Ingress is off unless an ingress class is set — the CRD says as much:
"If omitted, Ingress resources will not be supported by the ControlPlane."

| Piece | Value | Why |
| --- | --- | --- |
| `spec.controlPlaneOptions.ingressClass` | `kong` | Without it the control plane ignores every Ingress (verified: 404) |
| `IngressClass` object | `kong`, controller `ingress-controllers.konghq.com/kong` | Makes `ingressClassName: kong` resolve, and carries the default-class annotation |
| `ingressclass.kubernetes.io/is-default-class` | `--default-ic` (default `false`) | Claims Ingress objects that set no class |

The annotation is always written, `"true"` or `"false"`, so re-running `install` without
`--default-ic` releases the default instead of leaving a stale `"true"` behind.

Note Kong builds Ingress-derived routes as HTTPS-only: plain HTTP gets `426 Upgrade
Required` until the Ingress carries `konghq.com/protocols: http,https`. Gateway API
listeners are unaffected.

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
