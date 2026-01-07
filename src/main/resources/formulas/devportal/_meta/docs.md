# vkdr devportal

Use these commands to install and manage VeeCode DevPortal, a ready-to-use Backstage distribution.

**Note:** DevPortal currently requires Kong Gateway as the ingress controller.

## vkdr devportal install

Install VeeCode DevPortal in your cluster.

```bash
vkdr devportal install [-s] [--load-env] [--samples] \
  [-d=<domain>] [--profile=<profile>] [--location=<location>] \
  [--merge=<mergeValues>] [--npm=<npmRegistry>] \
  [--github-org=<github_org>] [--github-token=<github_token>] \
  [--github-app-id=<github_app_id>] [--github-client-id=<github_client_id>] \
  [--github-client-secret=<github_client_secret>] \
  [--github-auth-client-id=<github_auth_client_id>] \
  [--github-auth-client-secret=<github_auth_client_secret>] \
  [--github-private-key-base64=<github_private_key_base64>]
```

### Flags

| Flag | Shorthand | Description | Default |
|------|-----------|-------------|---------|
| `--domain` | `-d` | Domain name for the generated ingress | `localhost` |
| `--secure` | `-s` | Enable HTTPS | `false` |
| `--profile` | | DevPortal profile (see profiles below) | (none) |
| `--load-env` | | Load profile values from environment variables | `false` |
| `--samples` | | Install apps from sample catalog | `false` |
| `--location` | | Backstage catalog location (URL) | (none) |
| `--merge` | | Values file to merge with defaults | (none) |
| `--npm` | | NPM registry to use | (none) |

### GitHub Integration Flags

These flags are used with `github` or `github-pat` profiles:

| Flag | Description | Profile |
|------|-------------|---------|
| `--github-org` | GitHub organization name | `github`, `github-pat` |
| `--github-token` | GitHub personal access token | `github`, `github-pat` |
| `--github-app-id` | GitHub App ID | `github` |
| `--github-client-id` | GitHub App client ID (integrations) | `github` |
| `--github-client-secret` | GitHub App client secret (integrations) | `github` |
| `--github-auth-client-id` | GitHub OAuth App client ID (auth) | `github` |
| `--github-auth-client-secret` | GitHub OAuth App client secret (auth) | `github` |
| `--github-private-key-base64` | GitHub App private key (base64) | `github` |

### Profiles

| Profile | Description |
|---------|-------------|
| `github-pat` | GitHub with Personal Access Token (simplest) |
| `github` | GitHub with App authentication (recommended for production) |
| `gitlab` | GitLab integration |
| `azure` | Azure DevOps integration |
| `ldap` | LDAP authentication |

### Examples

#### Quick Start with Samples

```bash
vkdr infra up
vkdr kong install --default-ic
vkdr devportal install --samples
# Access at http://devportal.localhost:8000
```

#### GitHub PAT Profile

Using a Personal Access Token (simplest setup):

```bash
vkdr devportal install \
  --profile github-pat \
  --github-org myorg \
  --github-token ghp_xxxxxxxxxxxx
```

#### GitHub App Profile

Using GitHub App authentication (recommended):

```bash
vkdr devportal install \
  --profile github \
  --github-org myorg \
  --github-app-id 123456 \
  --github-client-id Iv1.xxxxxxxxxx \
  --github-client-secret xxxxxxxxxxxx \
  --github-auth-client-id xxxxxxxxxxxx \
  --github-auth-client-secret xxxxxxxxxxxx \
  --github-private-key-base64 LS0tLS1CRUdJTi...
```

#### Load from Environment Variables

Instead of passing flags, set environment variables and use `--load-env`:

```bash
export GITHUB_ORG=myorg
export GITHUB_TOKEN=ghp_xxxxxxxxxxxx

vkdr devportal install --profile github-pat --load-env
```

#### Custom Catalog Location

```bash
vkdr devportal install \
  --profile github-pat \
  --github-org myorg \
  --github-token ghp_xxxx \
  --location https://github.com/myorg/backstage-catalog/blob/main/catalog-info.yaml
```

#### With HTTPS

```bash
vkdr devportal install -d example.com -s --profile github-pat --github-org myorg --github-token ghp_xxxx
```

#### Merge Custom Values

```bash
vkdr devportal install \
  --profile github-pat \
  --github-org myorg \
  --github-token ghp_xxxx \
  --merge ./my-custom-values.yaml
```

## vkdr devportal remove

Remove VeeCode DevPortal from your cluster.

```bash
vkdr devportal remove
```

### Example

```bash
vkdr devportal remove
```

## vkdr devportal explain

Explain VeeCode DevPortal formulas and configuration options.

```bash
vkdr devportal explain
```

## Complete Examples

### Minimal Local Setup

```bash
# Start cluster
vkdr infra up

# Install Kong (required)
vkdr kong install --default-ic

# Install DevPortal with sample catalog
vkdr devportal install --samples

# Access DevPortal
open http://devportal.localhost:8000

# Clean up
vkdr devportal remove
vkdr kong remove
vkdr infra stop
```

### Production-like Setup with GitHub

```bash
# Start cluster
vkdr infra up

# Install dependencies
vkdr kong install --default-ic -s
vkdr postgres install -w
vkdr keycloak install

# Install DevPortal with GitHub integration
vkdr devportal install \
  --profile github \
  --github-org mycompany \
  --github-app-id 123456 \
  --github-client-id Iv1.xxxx \
  --github-client-secret xxxx \
  --github-auth-client-id xxxx \
  --github-auth-client-secret xxxx \
  --github-private-key-base64 xxxx \
  --location https://github.com/mycompany/backstage-catalog/blob/main/catalog-info.yaml \
  -s

# Access DevPortal
open https://devportal.localhost:8001
```

## Troubleshooting

### DevPortal not starting

Ensure Kong is installed and running:

```bash
vkdr kong install --default-ic
# Wait for Kong to be ready before installing DevPortal
```

### GitHub integration not working

1. Verify your token/credentials are correct
2. Check that your GitHub App has the required permissions
3. Use `--load-env` to avoid shell escaping issues with secrets

### Custom catalog not loading

Ensure the catalog URL is accessible and the YAML is valid:

```bash
curl -I https://github.com/myorg/catalog/blob/main/catalog-info.yaml
```

## Formula Examples

### Pre-requisites

- Start `vkdr` bound to ports 80/443
- Have a valid GitHub PAT token
- Add entries to `/etc/hosts`: devportal.localhost, petclinic.localhost → 127.0.0.1

```sh
vkdr infra start --http 80 --https 443
export GITHUB_TOKEN=your_github_pat_token
```

### Basic Installation

```sh
vkdr devportal install --github-token $GITHUB_TOKEN
```

This installs DevPortal with dependencies (Kong Gateway, Postgres). Available at http://devportal.localhost in guest mode.

### With Sample Applications

```sh
vkdr devportal install --github-token $GITHUB_TOKEN --samples
```

Sample apps included:
- ViaCEP API: `curl localhost/cep/20020080/json`
- Petclinic: http://petclinic.localhost/

### Custom Catalog

```sh
vkdr devportal install --github-token $GITHUB_TOKEN --location $YOUR_CATALOG_URL
```

### Plugin Development with Local NPM

Use with a local NPM registry (like Verdaccio) for dynamic plugin development:

```sh
verdaccio -l 0.0.0.0:4873
vkdr devportal install --github-token $GITHUB_TOKEN --npm http://host.k3d.internal:4873
```
