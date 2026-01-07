# VKDR - VeeCode Kubernetes Developer Runtime

VKDR is a CLI tool to accelerate local Kubernetes development. It provides opinionated, ready-to-use configurations for common development scenarios.

## Quick Start

```bash
# Install VKDR
curl -fsSL https://get.vkdr.dev | bash

# Initialize VKDR (downloads required tools)
vkdr init

# Start a local cluster with Traefik ingress
vkdr infra start --traefik

# Deploy a test service
vkdr whoami install
curl http://whoami.localhost:8000

# Clean up
vkdr whoami remove
vkdr infra stop
```

## Commands

### Infrastructure

| Command | Description | Docs |
|---------|-------------|------|
| `vkdr infra` | Manage local k3d cluster | `vkdr infra explain` |
| `vkdr init` | Initialize VKDR environment | `vkdr init --help` |
| `vkdr upgrade` | Upgrade VKDR to latest version | `vkdr upgrade --help` |

### Ingress Controllers

| Command | Description | Docs |
|---------|-------------|------|
| `vkdr kong` | Kong API Gateway | `vkdr kong explain` |
| `vkdr nginx` | NGinx Ingress Controller | `vkdr nginx explain` |
| `vkdr traefik` | Traefik Ingress Controller | `vkdr traefik explain` |
| `vkdr whoami` | Test service for ingress | `vkdr whoami explain` |

### Databases

| Command | Description | Docs |
|---------|-------------|------|
| `vkdr postgres` | PostgreSQL database | `vkdr postgres explain` |

### Identity & Access

| Command | Description | Docs |
|---------|-------------|------|
| `vkdr keycloak` | Keycloak identity management | `vkdr keycloak explain` |
| `vkdr openldap` | OpenLDAP directory service | `vkdr openldap explain` |

### Secrets Management

| Command | Description | Docs |
|---------|-------------|------|
| `vkdr vault` | HashiCorp Vault | `vkdr vault explain` |
| `vkdr eso` | External Secrets Operator | `vkdr eso explain` |

### Developer Portal

| Command | Description | Docs |
|---------|-------------|------|
| `vkdr devportal` | VeeCode DevPortal (Backstage) | `vkdr devportal explain` |

### Utilities

| Command | Description | Docs |
|---------|-------------|------|
| `vkdr mirror` | Container image mirrors | `vkdr mirror explain` |
| `vkdr grafana-cloud` | Grafana Cloud integration | `vkdr grafana-cloud explain` |

## Common Workflows

### Basic Development Setup

```bash
vkdr infra start --traefik
vkdr whoami install
# Your ingress is working at http://whoami.localhost:8000
```

### Full Stack with Database

```bash
vkdr infra up
vkdr kong install --default-ic
vkdr postgres install -w
vkdr keycloak install
# Kong at :8000, Keycloak at http://keycloak.localhost:8000
```

### DevPortal Setup

```bash
vkdr infra up
vkdr kong install --default-ic
vkdr devportal install --samples
# DevPortal at http://devportal.localhost:8000
```

### Secrets Management

```bash
vkdr infra up
vkdr vault install --dev
vkdr eso install
vkdr postgres install -w
vkdr postgres createdb -d myapp -u myuser --vault
# Database credentials managed by Vault + ESO
```

## Getting Help

- Run `vkdr --help` for all commands
- Run `vkdr <command> --help` for command options
- Run `vkdr <command> explain` for detailed documentation
- Visit https://docs.vkdr.dev for full documentation
- Report issues at https://github.com/veecode-platform/vkdr/issues

## Environment

VKDR stores its configuration and tools in `~/.vkdr/`:

```
~/.vkdr/
├── bin/          # Downloaded tools (kubectl, helm, k3d, etc.)
├── formulas/     # Command implementations
├── certs/        # Generated certificates
└── tmp/          # Temporary files
```
