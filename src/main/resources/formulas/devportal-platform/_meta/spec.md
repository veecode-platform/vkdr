# devportal-platform Formula Specification

Installs **VeeCode DevPortal V2** (the `devportal-platform` image line) from the published
`veecode-devportal-platform` Helm chart. Separate from the V1 `devportal` formula, which
stays as-is for the 1.x distro.

## Purpose

Deploy DevPortal V2 on a local VKDR cluster using the V2 runtime contract: **presets**
(`VEECODE_PRESETS`) instead of V1 profiles, a VKDR-managed credentials Secret consumed via
the chart's `existingSecret`, Kong ingress, and persistent SQLite (chart default).

## Key Files

| File | Purpose |
|------|---------|
| `install/formula.sh` | Compose presets, build the credentials Secret, install the chart from the next-charts Helm repo |
| `remove/formula.sh` | Remove the release + VKDR-owned Secret and kubernetes-preset RBAC |
| `_shared/values/devportal-platform-common.yaml` | V2-surface Helm values template |

## Behaviour

- `--presets` sets the base list; `github` / `github-auth` / `kubernetes` are auto-added
  when their credentials/flags are provided.
- GitHub is PAT + OAuth only (no GitHub App): `--github-pat` + `--github-org` → `github`
  preset; `--github-auth-client-id` + `--github-auth-client-secret` → `github-auth` preset.
- `--with-kubernetes` makes VKDR create a read-only ServiceAccount + ClusterRole + token
  (chart `rbac.clusterRoles.create` stays false) and wires `K8S_CLUSTER_*` into the Secret.
- Credentials live only in a VKDR-created Secret (referenced via `existingSecret`), never
  in the Helm release values.
- Missing required preset variables fail the boot fast (exit 78) — not masked.

## Version sync

The chart pins the image; this formula consumes whatever chart version is published. See the
chart's `RELEASE.md` for the image↔chart version-sync rule.
