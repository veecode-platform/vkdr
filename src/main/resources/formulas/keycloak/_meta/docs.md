# vkdr keycloak

Use these commands to manage Keycloak identity and access management in your `vkdr` cluster.

## vkdr keycloak install

Install Keycloak in your cluster.

```bash
vkdr keycloak install [-s] [-d=<domain>] \
  [-p=<admin_password>] [-u=<admin_user>]
```

### Flags

| Flag | Shorthand | Description | Default |
|------|-----------|-------------|---------|
| `--domain` | `-d` | Domain name for the generated ingress | `localhost` |
| `--secure` | `-s` | Enable HTTPS | `false` |
| `--user` | `-u` | Keycloak admin user | `admin` |
| `--password` | `-p` | Keycloak admin password | `admin` |

### Examples

Install Keycloak with default settings:

```bash
vkdr infra up
vkdr nginx install --default-ic
vkdr keycloak install
# Access at http://keycloak.localhost:8000
```

Install with custom domain and HTTPS:

```bash
vkdr keycloak install -d example.com -s
```

Install with custom admin credentials:

```bash
vkdr keycloak install -u myadmin -p mysecretpassword
```

## vkdr keycloak remove

Remove Keycloak from your cluster.

```bash
vkdr keycloak remove
```

### Example

```bash
vkdr keycloak remove
```

## vkdr keycloak export

Export a Keycloak realm configuration to a file.

```bash
vkdr keycloak export  [-a=<admin_password>] \
  [-f=<export_file>] [-r=<realm_name>]
```

### Flags

| Flag | Shorthand | Description | Default |
|------|-----------|-------------|---------|
| `--admin` | `-a` | Admin password | (optional) |
| `--file` | `-f` | Realm export file path | (optional) |
| `--realm` | `-r` | Realm name to export | (optional) |

### Examples

Export the default realm:

```bash
vkdr keycloak export -r master -f master-realm.json
```

Export with admin password:

```bash
vkdr keycloak export -a adminpassword -r vkdr -f vkdr-realm.json
```

## vkdr keycloak import

Import a Keycloak realm configuration from a file.

```bash
vkdr keycloak import  [-a=<admin_password>] \
  [-f=<import_file>]
```

### Flags

| Flag | Shorthand | Description | Default |
|------|-----------|-------------|---------|
| `--admin` | `-a` | Admin password | (optional) |
| `--file` | `-f` | Realm import file path | (optional) |

### Examples

Import a realm configuration:

```bash
vkdr keycloak import -f my-realm.json
```

Import with admin password:

```bash
vkdr keycloak import -a adminpassword -f my-realm.json
```

## vkdr keycloak explain

Explain Keycloak formulas and configuration options.

```bash
vkdr keycloak explain
```

## Complete Example

Here's a complete workflow for setting up Keycloak:

```bash
# Start cluster with ingress
vkdr infra up
vkdr nginx install --default-ic

# Install Keycloak
vkdr keycloak install -u admin -p admin123

# Access Keycloak Admin Console
# http://keycloak.localhost:8000
# Login with admin/admin123

# After configuring realms, export for backup
vkdr keycloak export -a admin123 -r myrealm -f myrealm-backup.json

# To restore on another cluster
vkdr keycloak import -a admin123 -f myrealm-backup.json

# Clean up
vkdr keycloak remove
```

## Integration with Kong

Keycloak can be used with Kong Gateway for OIDC authentication:

```bash
vkdr infra up
vkdr kong install --default-ic --oidc
vkdr keycloak install

# Kong Admin UI will use Keycloak for authentication
# Requires 'vkdr' realm with 'kong-admin' OpenID Connect client
```

## Formula Examples

### Basic Installation

```sh
vkdr infra up
vkdr postgres install
vkdr nginx install --default-ic
vkdr keycloak install
```

### Notes

- The "install" command installs the Keycloak operator first, then the Keycloak server
- If PostgreSQL is not present, it will be installed automatically
- The Keycloak database is also created automatically
- The "remove" command does NOT remove the Keycloak operator, only the server and database
