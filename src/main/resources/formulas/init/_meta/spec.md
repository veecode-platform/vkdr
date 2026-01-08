# init Formula Specification

Simple formula. Inspect formula files directly for implementation details.

## Purpose

Initializes VKDR by downloading required CLI tools to `~/.vkdr/bin/`.

## Key Files

| File | Purpose |
|------|---------|
| `formula.sh` | Download and install all tools |
| `_shared/lib/tools-versions.sh` | Tool version definitions |
| `_shared/bin/download-glow.sh` | Glow installation helper |

## Tools Installed

| Tool | Purpose |
|------|---------|
| arkade | Tool installer (used to install other tools) |
| kubectl | Kubernetes CLI |
| k3d | k3s-in-Docker CLI |
| helm | Kubernetes package manager |
| jq | JSON processor |
| yq | YAML processor |
| glow | Markdown renderer |
| vault | HashiCorp Vault CLI |

## Parameters

| Parameter | Description |
|-----------|-------------|
| `--force` | Reinstall all tools even if present |
