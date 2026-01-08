# upgrade Formula Specification

Simple formula. Inspect formula files directly for implementation details.

## Purpose

Upgrades VKDR CLI binary to the latest release from GitHub.

## Key Files

| File | Purpose |
|------|---------|
| `formula.sh` | Version comparison and upgrade logic |
| `get-vkdr.sh` | Download and install new binary |

## Behavior

1. Fetches latest release tag from GitHub API
2. Compares with current version
3. Downloads and installs if newer version available
4. Skips if current >= latest (unless `--force`)

## Parameters

| Parameter | Description |
|-----------|-------------|
| `--force` | Upgrade even if current version is equal or higher |
