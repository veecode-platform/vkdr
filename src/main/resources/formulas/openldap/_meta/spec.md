# openldap Formula Specification

Simple formula. Inspect formula files directly for implementation details.

## Purpose

Installs OpenLDAP server with optional phpLDAPadmin and Self-Service-Password UIs. Useful for testing LDAP authentication.

## Key Files

| File | Purpose |
|------|---------|
| `install/formula.sh` | Deploy openldap-stack-ha via Helm |
| `remove/formula.sh` | Remove openldap Helm release |
| `_shared/values/openldap.yaml` | Helm values with LDIF configs |

## Features

- Pre-loaded with sample users and groups (LDIF files)
- phpLDAPadmin web UI via `--ldap-admin` flag
- Self-Service-Password UI via `--ssp` flag
- NodePort for direct LDAP access

## Default Domain

`dc=vee,dc=codes` - hardcoded in formula.

## Updating

Uses latest `helm-openldap/openldap-stack-ha` chart version. No version pin - updates happen automatically. Tests will catch breaking changes.

See `_meta/update.yaml` for automation config.
