# vkdr openldap

Use these commands to install and manage OpenLDAP directory service in your `vkdr` cluster.

OpenLDAP provides a directory service for user authentication and authorization. It's commonly used for enterprise authentication with DevPortal and other applications.

## vkdr openldap install

Install OpenLDAP in your cluster.

```bash
vkdr openldap install [-s] [--ldap-admin] [--ssp] \
  [-d=<domain>] [--nodePort=<nodePort>] [-p=<admin_password>] [-u=<admin_user>]
```

### Flags

| Flag | Shorthand | Description | Default |
|------|-----------|-------------|---------|
| `--domain` | `-d` | Domain name for the generated ingress | `localhost` |
| `--secure` | `-s` | Enable HTTPS | `false` |
| `--user` | `-u` | OpenLDAP admin user | `admin` |
| `--password` | `-p` | OpenLDAP admin password | `admin` |
| `--ldap-admin` | | Enable phpLDAPadmin web UI | `false` |
| `--ssp` | | Enable self-service-password web UI | `false` |
| `--nodePort` | | NodePort for LDAP service | `30000` |

### Examples

#### Basic Installation

```bash
vkdr infra start --nodeports 1
vkdr openldap install
# LDAP available on localhost:9000 (nodeport 30000)
```

#### With phpLDAPadmin Web UI

```bash
vkdr infra up
vkdr nginx install --default-ic
vkdr openldap install --ldap-admin
# phpLDAPadmin at http://ldapadmin.localhost:8000
```

#### With Self-Service Password

Enable users to reset their own passwords:

```bash
vkdr openldap install --ldap-admin --ssp
# Self-service password at http://ssp.localhost:8000
```

#### With Custom Credentials

```bash
vkdr openldap install -u myadmin -p mysecretpassword --ldap-admin
```

#### With HTTPS

```bash
vkdr openldap install -d example.com -s --ldap-admin --ssp
```

## vkdr openldap remove

Remove OpenLDAP from your cluster.

```bash
vkdr openldap remove [-d]
```

### Flags

| Flag | Shorthand | Description | Default |
|------|-----------|-------------|---------|
| `--delete` | `-d` | Delete the associated PVC (data-openldap-0) | `false` |

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

## Complete Examples

### DevPortal with LDAP Authentication

```bash
# Start cluster with nodeports for LDAP
vkdr infra start --nodeports 1

# Install ingress
vkdr nginx install --default-ic

# Install OpenLDAP with admin UI
vkdr openldap install --ldap-admin -p ldapadmin123

# Access phpLDAPadmin to manage users
open http://ldapadmin.localhost:8000
# Login DN: cn=admin,dc=vkdr,dc=local
# Password: ldapadmin123

# Install Kong for DevPortal
vkdr kong install --default-ic

# Install DevPortal with LDAP profile
vkdr devportal install --profile ldap
```

### Full LDAP Setup with Self-Service

```bash
# Start cluster
vkdr infra start --nodeports 1
vkdr nginx install --default-ic

# Install OpenLDAP with all features
vkdr openldap install \
  -u admin \
  -p adminpassword \
  --ldap-admin \
  --ssp

# Access points:
# - phpLDAPadmin: http://ldapadmin.localhost:8000
# - Self-Service Password: http://ssp.localhost:8000
# - LDAP: localhost:9000 (ldap://localhost:9000)
```

## LDAP Connection Details

### Default Base DN

```
dc=vkdr,dc=local
```

### Admin Bind DN

```
cn=admin,dc=vkdr,dc=local
```

### Connection URL

```
ldap://localhost:9000
```

Or within the cluster:

```
ldap://openldap.openldap.svc.cluster.local:389
```

## Using phpLDAPadmin

phpLDAPadmin provides a web interface for managing LDAP:

1. Access http://ldapadmin.localhost:8000
2. Click "login"
3. Login DN: `cn=admin,dc=vkdr,dc=local`
4. Password: Your admin password (default: `admin`)

### Creating Users

1. Navigate to `dc=vkdr,dc=local`
2. Create a new child entry
3. Select "Generic: User Account"
4. Fill in user details

### Creating Groups

1. Navigate to `dc=vkdr,dc=local`
2. Create a new child entry
3. Select "Generic: Posix Group"
4. Add members to the group

## Self-Service Password

When `--ssp` is enabled, users can reset their own passwords:

1. Access http://ssp.localhost:8000
2. Enter username
3. Follow password reset flow

This is useful for enterprise environments where users need to manage their own credentials.
