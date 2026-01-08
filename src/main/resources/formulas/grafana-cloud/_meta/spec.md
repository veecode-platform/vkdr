# grafana-cloud Formula Specification

Simple formula. Inspect formula files directly for implementation details.

## Purpose

Installs Grafana Cloud agent (k8s-monitoring) to send metrics, logs, and traces to Grafana Cloud.

## Key Files

| File | Purpose |
|------|---------|
| `install/formula.sh` | Deploy k8s-monitoring with cloud token |
| `remove/formula.sh` | Remove grafana-cloud Helm release |
| `_shared/values/grafana-cloud.yaml` | Helm values with Prometheus/Loki/Tempo config |

## Parameters

| Parameter | Description |
|-----------|-------------|
| `--token` | Grafana Cloud API token (required) |

## Note

Requires a Grafana Cloud account. Token is used for Prometheus, Loki, and Tempo authentication.

## Updating

Uses latest `grafana/k8s-monitoring` chart version. No version pin - updates happen automatically. May need to update values file if Grafana Cloud API changes.

See `_meta/update.yaml` for automation config.
