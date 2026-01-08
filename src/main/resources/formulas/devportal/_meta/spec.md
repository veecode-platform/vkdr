# devportal Formula Specification

Complex formula with many parameters. Inspect formula files directly for full implementation details.

## Purpose

Installs VeeCode DevPortal (Backstage-based Internal Developer Portal) with GitHub integration.

## Key Files

| File | Purpose |
|------|---------|
| `install/formula.sh` | Deploy devportal with secrets and Kong |
| `remove/formula.sh` | Remove devportal Helm release |
| `_shared/values/devportal-common.yaml` | Helm values template |
| `_shared/sample-apps/` | Sample applications for catalog |

## Features

- Multiple authentication profiles: `github`, `github-pat`, `gitlab` (planned)
- Auto-installs Kong as ingress controller
- Service account token for Kubernetes plugin
- Sample apps deployment option
- Custom catalog locations

## Parameters (16 total)

Key parameters:
- `--domain`: Base domain
- `--profile`: Auth profile (github, github-pat)
- `--github-token`: GitHub PAT
- `--github-client-id/secret`: OAuth app credentials
- `--github-app-id`: GitHub App ID
- `--github-org`: Organization name
- `--samples`: Install sample apps
- `--load-env`: Load from environment variables
