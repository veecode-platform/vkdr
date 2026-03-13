# crossplane Formula Specification

## Purpose

Installs the Crossplane runtime via the stable Helm chart. Optionally installs a Crossplane provider with credentials and ProviderConfig in one command.

## Key Files

| File | Purpose |
| --- | --- |
| `install/formula.sh` | Install Crossplane via Helm, optionally configure a provider |
| `remove/formula.sh` | Remove Crossplane Helm release and namespace |

## Design Decisions

- **No version pinning for Crossplane**: Uses `helm-latest` strategy — always installs the latest stable chart version. Tests catch breaking changes.
- **Provider versions are pinned**: Provider packages use specific versions to ensure compatibility.
- **Provider install is atomic**: When `--provider` is specified, the formula installs the provider package, creates credentials, and applies the ProviderConfig in one operation.
- **Secret recreation**: Credentials secrets are deleted and recreated (not patched) to ensure the latest value is always applied.
- **Default ProviderConfig**: The ProviderConfig CR is always named `default`, which is the Crossplane convention for the default provider configuration.
- **Namespace**: Uses `crossplane-system` (Crossplane convention), created via `--create-namespace`.

## Supported Providers

| Provider | `--provider` value | Package | Credential flag |
| --- | --- | --- | --- |
| DigitalOcean | `do` | `xpkg.upbound.io/crossplane-contrib/provider-upjet-digitalocean:v0.3.0` | `--do-token` |
| AWS (S3) | `aws` | `xpkg.upbound.io/upbound/provider-aws-s3:v1.22.0` | `--aws-credential-file` |

## Updating

Uses `crossplane-stable/crossplane` Helm chart without version pinning. No manual update needed — tests validate compatibility with latest chart.

Provider package versions are pinned in `install/formula.sh` and should be updated when new versions are released.

See `_meta/update.yaml` for automation config.
