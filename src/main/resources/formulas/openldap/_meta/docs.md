# vkdr openldap

Use these commands to install and manage an OpenLDAP directory service in your `vkdr` cluster.

OpenLDAP provides a directory service for user authentication and authorization. It is commonly used for enterprise authentication with DevPortal and other applications.

The formula ships with a pre-seeded directory tree (base DN `dc=vee,dc=codes`) and a few sample users and groups, ready for local development.

## vkdr openldap install

Install OpenLDAP in your cluster.

```bash
vkdr openldap install [-s] [--ldap-admin] [--ssp] \
  [-d=<domain>] [--nodePort=<nodePort>] [-p=<admin_password>] [-u=<admin_user>]
```

### Flags

| Flag | Shorthand | Description | Default |
| --- | --- | --- | --- |
| `--domain` | `-d` | Domain name used for ingress hosts (`ldap.<domain>`, `ldap-ssp.<domain>`) | `localhost` |
| `--secure` | `-s` | Use HTTPS URLs in messages | `false` |
| `--user` | `-u` | OpenLDAP admin user (CN) | `admin` |
| `--password` | `-p` | OpenLDAP admin and config password | `admin` |
| `--ldap-admin` |  | Enable the phpLDAPadmin web UI | `false` |
| `--ssp` |  | Enable the self-service-password web UI | `false` |
| `--nodePort` |  | NodePort exposing LDAP (port 389 inside the container) | `30000` |

The NodePort is only reachable from the host when the cluster was started with `vkdr infra start --nodeports N` (with `N >= 1`). The first nodeport slot maps `30000 -> localhost:9000`.

### Examples

#### Basic installation

```bash
vkdr infra start --nodeports 1
vkdr openldap install
# LDAP reachable at ldap://localhost:9000
```

#### With phpLDAPadmin web UI

```bash
vkdr infra start --nodeports 1
vkdr nginx install --default-ic
vkdr openldap install --ldap-admin
# phpLDAPadmin at http://ldap.localhost:8000
```

#### With self-service-password

```bash
vkdr openldap install --ldap-admin --ssp
# phpLDAPadmin at      http://ldap.localhost:8000
# self-service-password at http://ldap-ssp.localhost:8000
```

#### Custom credentials

```bash
vkdr openldap install -u admin -p mysecretpassword --ldap-admin
```

## vkdr openldap remove

Remove OpenLDAP from your cluster.

```bash
vkdr openldap remove [-d]
```

### Flags

| Flag | Shorthand | Description | Default |
| --- | --- | --- | --- |
| `--delete` | `-d` | Delete the associated PVC (`data-openldap-0`) | `false` |

### Examples

Remove OpenLDAP but keep data:

```bash
vkdr openldap remove
```

Remove OpenLDAP and delete all data:

```bash
vkdr openldap remove -d
```

## vkdr openldap explain

Explain OpenLDAP setup and configuration options.

```bash
vkdr openldap explain
```

## LDAP connection details

### Base DN

```pre
dc=vee,dc=codes
```

### Admin bind DN

```pre
cn=admin,dc=vee,dc=codes
```

The admin password is whatever you passed via `-p` (default: `admin`).

### Connection URLs

From the host (requires `vkdr infra start --nodeports 1`):

```pre
ldap://localhost:9000
```

From inside the cluster:

```pre
ldap://openldap.vkdr.svc.cluster.local:389
```

### Quick sanity checks

```bash
# Bind as admin
ldapwhoami -H ldap://localhost:9000 -x \
  -D "cn=admin,dc=vee,dc=codes" -w admin

# List everything under the base DN
ldapsearch -LLL -H ldap://localhost:9000 -x \
  -D "cn=admin,dc=vee,dc=codes" -w admin \
  -b "dc=vee,dc=codes" "(objectClass=*)" dn
```

## Pre-seeded directory

The formula loads three LDIF files on first install (from `_shared/values/openldap.yaml`). You can edit that file to change the seed data before installing.

### Organizational units

| DN | Purpose |
| --- | --- |
| `dc=vee,dc=codes` | Root (organization "Vee Codes") |
| `ou=People,dc=vee,dc=codes` | Users |
| `ou=Groups,dc=vee,dc=codes` | Groups |

### Users

| DN | cn | mail | Password |
| --- | --- | --- | --- |
| `uid=admin,ou=People,dc=vee,dc=codes` | Admin Superuser | `admin@vee.codes` | `vert1234` |
| `uid=young,ou=People,dc=vee,dc=codes` | Young Trainee | `young@vee.codes` | `vert1234` |

Sample user passwords are stored as pre-computed `{SSHA}` hashes in `_shared/values/openldap.yaml`. The seeded password for both users is `vert1234`. To use different passwords, replace the `userPassword` hashes in that file (generate with `slappasswd -h '{SSHA}' -s <password>`) before running `vkdr openldap install`.

Note: the `-p` / admin password flag only sets the rootDN bind password (`cn=admin,dc=vee,dc=codes`). It does not affect the pre-seeded user entries under `ou=People`.

### Groups

Both groups use `objectClass: groupOfNames`.

| DN | Members |
| --- | --- |
| `cn=developers,ou=Groups,dc=vee,dc=codes` | `admin`, `young` |
| `cn=admins,ou=Groups,dc=vee,dc=codes` | `admin` |

## Using phpLDAPadmin

When installed with `--ldap-admin`, phpLDAPadmin is available at `http://ldap.<domain>:8000` (default: `http://ldap.localhost:8000`).

1. Open the URL
2. Click "login"
3. Login DN: `cn=admin,dc=vee,dc=codes`
4. Password: whatever you passed to `-p` (default: `admin`)

From there you can browse `dc=vee,dc=codes`, create users under `ou=People`, or add members to groups under `ou=Groups`.

## Self-service-password

When installed with `--ssp`, a self-service-password UI is available at `http://ldap-ssp.<domain>:8000` (default: `http://ldap-ssp.localhost:8000`). Users can reset their own passwords there without admin intervention.

## Complete example: DevPortal with LDAP authentication

```bash
# Cluster with one exposed nodeport for LDAP
vkdr infra start --nodeports 1

# Ingress for the web UIs
vkdr nginx install --default-ic

# OpenLDAP with the admin UI
vkdr openldap install --ldap-admin -p ldapadmin123

# Browse the directory:
#   http://ldap.localhost:8000
#   DN: cn=admin,dc=vee,dc=codes
#   Password: ldapadmin123

# Kong and DevPortal wired to LDAP
vkdr kong install --default-ic
vkdr devportal install --profile ldap
```
