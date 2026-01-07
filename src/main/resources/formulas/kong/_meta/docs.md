# vkdr kong

Use these commands to install and manage Kong Gateway as an ingress controller in your `vkdr` cluster.

Kong Gateway is a powerful API gateway that can be used as an ingress controller with advanced features like rate limiting, authentication, and more.

## vkdr kong install

Install Kong Gateway in your cluster.

```bash
vkdr kong install [-es] [--acme] [--api] [--default-ic] [--oidc] \
  [--use-nodeport] [--acme-server=<acme_server>] [-d=<domain>] \
  [-i=<image_name>] [-l=<license>] [--log-level=<log_level>] \
  [-m=<kong_mode>] [-p=<admin_password>] [--proxy-tls-secret=<proxy_tls_secret>] \
  [-t=<image_tag>] [--env=<String=String>]... [--label=<String=String>]...
```

### Flags

| Flag | Shorthand | Description | Default |
|------|-----------|-------------|---------|
| `--domain` | `-d` | Domain name for the generated ingress | `localhost` |
| `--secure` | `-s` | Enable HTTPS | `false` |
| `--enterprise` | `-e` | Run Kong Gateway enterprise image | `false` |
| `--mode` | `-m` | Kong mode: `dbless`, `standard`, or `hybrid` | `dbless` |
| `--admin` | `-p` | Kong admin password | `vkdr1234` |
| `--default-ic` | | Make Kong the cluster's default ingress controller | `false` |
| `--api` | | Expose gateway endpoint at `api.DOMAIN` | `false` |
| `--acme` | | Enable ACME plugin globally for automatic TLS | `false` |
| `--acme-server` | | ACME server: `staging` or `production` | `staging` |
| `--oidc` | | Enable OIDC authentication for Admin API/UI | `false` |
| `--use-nodeport` | | Use NodePort instead of LoadBalancer | `false` |
| `--image` | `-i` | Kong image name | (chart default) |
| `--tag` | `-t` | Kong image tag | (chart default) |
| `--license` | `-l` | Kong license file (for enterprise) | (none) |
| `--proxy-tls-secret` | | Secret with default TLS certificate for proxy | (none) |
| `--log-level` | | Kong log level | (default) |
| `--env` | | Kong environment variables (repeatable) | (none) |
| `--label` | | Custom labels for Kong resources (repeatable) | (none) |

### Examples

#### Basic Installation

Install Kong as the default ingress controller:

```bash
vkdr infra up
vkdr kong install --default-ic
# Access Kong at http://localhost:8000
```

#### With Custom Domain and HTTPS

```bash
vkdr kong install -d example.com -s --default-ic
```

#### Enterprise Mode

```bash
vkdr kong install -e -l /path/to/license.json --default-ic
```

#### With OIDC Authentication (Keycloak)

```bash
vkdr infra up
vkdr keycloak install
vkdr kong install --default-ic --oidc
# Kong Admin UI uses Keycloak for authentication
# Requires 'vkdr' realm with 'kong-admin' OpenID Connect client
```

#### With ACME (Let's Encrypt)

```bash
vkdr kong install -d myapp.example.com -s --acme --acme-server production --default-ic
```

#### Using NodePort

When using NodePort mode, Kong uses ports 30000-30001:

```bash
# Start cluster with nodeports exposed
vkdr infra start --nodeports 2

# Install Kong with NodePort
vkdr kong install --use-nodeport --default-ic
# Access via http://localhost:9000
```

#### With Custom Environment Variables

```bash
vkdr kong install --default-ic \
  --env KONG_NGINX_WORKER_PROCESSES=2 \
  --env KONG_MEM_CACHE_SIZE=128m
```

#### With Custom Labels

```bash
vkdr kong install --default-ic \
  --label environment=development \
  --label team=platform
```

## vkdr kong remove

Remove Kong Gateway from your cluster.

```bash
vkdr kong remove
```

### Example

```bash
vkdr kong remove
```

## vkdr kong explain

Explain Kong install formulas and configuration options.

```bash
vkdr kong explain
```

## Complete Examples

### Basic API Gateway Setup

```bash
# Start cluster
vkdr infra up

# Install Kong
vkdr kong install --default-ic

# Install a test service
vkdr whoami install

# Test access
curl http://whoami.localhost:8000

# Clean up
vkdr whoami remove
vkdr kong remove
```

### Full Stack with DevPortal

Kong is required for VeeCode DevPortal:

```bash
# Start cluster
vkdr infra up

# Install Kong as ingress
vkdr kong install --default-ic

# Install DevPortal
vkdr devportal install

# Access DevPortal at http://devportal.localhost:8000
```

### Production-like Setup with OIDC

```bash
# Start cluster
vkdr infra up

# Install Keycloak for identity management
vkdr keycloak install

# Install Kong with OIDC
vkdr kong install --default-ic --oidc -s

# Kong Admin UI now requires Keycloak authentication
```

## Kong Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| `dbless` | No database, declarative config | Development, simple setups |
| `standard` | PostgreSQL database | Production, dynamic config |
| `hybrid` | Control plane + data planes | Large scale deployments |

### Standard Mode with Database

```bash
# Install PostgreSQL first
vkdr postgres install -w

# Install Kong in standard mode
vkdr kong install -m standard --default-ic
```

## Formula Examples

### Kong OSS in db-less mode

```sh
vkdr infra up
vkdr kong install
```

- Kong: http://localhost:8000
- Kong Manager: http://manager.localhost:8000/manager
- Kong Admin API: http://manager.localhost:8000

### Kong OSS in standard (traditional) mode

```sh
vkdr infra up
vkdr kong install -m standard
```

A Postgres database is also deployed in the cluster automatically, passwords are generated randomly.

### Kong OSS with shared database

```sh
vkdr infra up
vkdr postgres install
vkdr postgres createdb -d kong -u kong -p kong -s
vkdr kong install -m standard
```

The "kong" database user's password is kept in a secret named `kong-pg-secret`.

### Kong OSS with custom domain

```sh
vkdr infra start --http 80 --https 443
vkdr kong install -m standard -d mydomain.com -s
```

- Kong: ports 80 and 443 on host's public IP
- Kong Manager: https://manager.mydomain.com/manager

The `-d` domain flag is a suffix for "manager.DOMAIN" endpoints. The `-s` flag generates self-signed TLS certificates.

### Kong Enterprise as secondary Ingress Controller

```sh
vkdr infra start --traefik --nodeports=2
vkdr kong install -e -l /path/license.json -m standard -p mypassword --use-nodeport
```

Two ingress controllers: Traefik (8000/8001) and Kong (9000/9001). If license is provided, RBAC is enabled (user "kong_admin").

### Kong Enterprise with custom domain

```sh
vkdr infra start --http 80 --https 443
vkdr kong install -e -l /path/license.json -m standard -p mypassword --default-ic -d mydomain.com -s
```

Kong is the default ingress controller with RBAC enabled.

### Kong with custom image (custom plugins)

```sh
vkdr infra up
vkdr kong install -m standard -i veecode/kong-cred -t 3.6.1-r1 \
  --env "plugins=bundled,oidc,oidc-acl,mtls-auth,mtls-acl,late-file-log"
```

Custom image with additional plugins pulled from Docker Hub.
