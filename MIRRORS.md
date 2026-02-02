# VKDR Container Image Mirrors

This document lists the container images used by each VKDR formula and their source registries.
Configure mirrors for these registries using `vkdr mirror add <registry>` to avoid rate limits.

## Default Mirrors

VKDR comes pre-configured with mirrors for:

- `docker.io` (Docker Hub)
- `registry.k8s.io` (Kubernetes registry)
- `ghcr.io` (GitHub Container Registry)

## Images by Formula

| Formula | Mirror | Image |
| --- | --- | --- |
| whoami | docker.io | cowboysysop/whoami |
| kong | docker.io | kong |
| kong (enterprise) | docker.io | kong/kong-gateway |
| kong-gw | docker.io | kong/kubernetes-ingress-controller |
| nginx | registry.k8s.io | ingress-nginx/controller |
| nginx-gw | ghcr.io | nginx/nginx-gateway-fabric |
| postgres | ghcr.io | cloudnative-pg/cloudnative-pg |
| postgres | ghcr.io | cloudnative-pg/postgresql |
| keycloak | quay.io | keycloak/keycloak |
| keycloak | quay.io | keycloak/keycloak-operator |
| vault | docker.io | hashicorp/vault |
| eso | ghcr.io | external-secrets/external-secrets |
| grafana-cloud | docker.io | grafana/grafana |
| grafana-cloud | docker.io | grafana/alloy |
| devportal | ghcr.io | veecode-platform/devportal |
| traefik | docker.io | traefik |
| openldap | docker.io | osixia/openldap |

## Adding Custom Mirrors

To add a mirror for a registry not in the default list (e.g., quay.io for Keycloak):

```bash
vkdr mirror add quay.io
```

Then restart the infrastructure:

```bash
vkdr infra stop --registry
vkdr infra up
```

## Listing Configured Mirrors

```bash
vkdr mirror list
```
