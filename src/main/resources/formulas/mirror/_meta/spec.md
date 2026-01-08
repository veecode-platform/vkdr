# mirror Formula Specification

Simple formula. Inspect formula files directly for implementation details.

## Purpose

Manages container registry mirrors for the k3d cluster. Mirrors cache images locally to speed up pulls and avoid rate limits.

## Key Files

| File | Purpose |
|------|---------|
| `add/formula.sh` | Add new registry mirror to config |
| `remove/formula.sh` | Remove registry mirror from config |
| `list/formula.sh` | List configured mirrors |
| `~/.vkdr/formulas/_shared/configs/mirror-registry.yaml` | Mirror configuration |

## Usage

```bash
vkdr mirror add ghcr.io      # Add GitHub Container Registry mirror
vkdr mirror list             # Show configured mirrors
vkdr infra stop && vkdr infra start  # Restart to apply changes
```

## Note

Changes require cluster restart to take effect. No external dependencies to update.
