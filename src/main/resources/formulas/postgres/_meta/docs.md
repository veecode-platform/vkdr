# vkdr postgres

Use these commands to manage a PostgreSQL database in your `vkdr` cluster.

## vkdr postgres install

Install a PostgreSQL database in your cluster.

```bash
vkdr postgres install [-w] [-p=<admin_password>]
```

### Flags

| Flag | Shorthand | Description | Default |
|------|-----------|-------------|---------|
| `--admin` | `-p` | Postgres admin password | (generated) |
| `--wait` | `-w` | Wait until Postgres is ready | `false` |

### Examples

Install PostgreSQL with default settings:

```bash
vkdr infra up
vkdr postgres install
```

Install with a specific admin password and wait for readiness:

```bash
vkdr postgres install -p mypassword -w
```

## vkdr postgres remove

Remove PostgreSQL from your cluster.

```bash
vkdr postgres remove [-d]
```

### Flags

| Flag | Shorthand | Description | Default |
|------|-----------|-------------|---------|
| `--delete` | `-d` | Delete postgres storage (PVC) after removal | `false` |

### Examples

Remove PostgreSQL but keep data:

```bash
vkdr postgres remove
```

Remove PostgreSQL and delete all data:

```bash
vkdr postgres remove -d
```

## vkdr postgres createdb

Create a new database with an optional user/password as its owner.

```bash
vkdr postgres createdb [-s] [--drop] [--vault] \
  [-a=<admin_password>] -d=<database_name> \
  [-p=<password>] [-u=<user_name>] \
  [--vault-rotation=<vault_rotation_schedule>]
```

### Flags

| Flag | Shorthand | Description | Default |
|------|-----------|-------------|---------|
| `--database` | `-d` | New database name | (required) |
| `--user` | `-u` | New user name | (optional) |
| `--password` | `-p` | New user's password | (optional) |
| `--admin` | `-a` | Admin password | (optional) |
| `--store` | `-s` | Store password in Kubernetes secret | `false` |
| `--drop` | | Drop database if it exists | `false` |
| `--vault` | | Create Vault database engine config | `false` |
| `--vault-rotation` | | Vault secret rotation schedule | `0 * * * SAT` |

### Examples

Create a simple database:

```bash
vkdr postgres createdb -d myapp
```

Create a database with user and store credentials in Kubernetes secret:

```bash
vkdr postgres createdb -d myapp -u myuser -p mypassword -s
```

Create a database with Vault integration:

```bash
vkdr postgres createdb -d myapp -u myuser --vault
```

## vkdr postgres dropdb

Drop a database and its associated secrets in Kubernetes.

```bash
vkdr postgres dropdb  -d=<database_name> [-u=<user_name>]
```

### Flags

| Flag | Shorthand | Description | Default |
|------|-----------|-------------|---------|
| `--database` | `-d` | Database name to drop | (required) |
| `--user` | `-u` | Database user/role name to remove | (optional) |

### Examples

Drop a database:

```bash
vkdr postgres dropdb -d myapp
```

Drop a database and its associated user:

```bash
vkdr postgres dropdb -d myapp -u myuser
```

## vkdr postgres listdbs

List all databases managed by the PostgreSQL cluster.

```bash
vkdr postgres listdbs [--json]
```

### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--json` | Output in JSON format | `false` |

### Examples

List all databases:

```bash
vkdr postgres listdbs
```

List databases in JSON format:

```bash
vkdr postgres listdbs --json
```

## vkdr postgres pingdb

Test database connectivity by running a simple SELECT query.

```bash
vkdr postgres pingdb  -d=<database_name> -u=<user_name>
```

### Flags

| Flag | Shorthand | Description | Default |
|------|-----------|-------------|---------|
| `--database` | `-d` | Database name to test | (required) |
| `--user` | `-u` | Database user name for connection | (required) |

### Examples

Test database connectivity:

```bash
vkdr postgres pingdb -d myapp -u myuser
```

## vkdr postgres explain

Explain PostgreSQL install formulas and configuration options.

```bash
vkdr postgres explain
```

## Complete Example

Here's a complete workflow for setting up PostgreSQL with an application database:

```bash
# Start cluster
vkdr infra up

# Install PostgreSQL and wait for it to be ready
vkdr postgres install -w

# Create application database with credentials stored in K8s secret
vkdr postgres createdb -d myapp -u appuser -p apppassword -s

# Verify database is accessible
vkdr postgres pingdb -d myapp -u appuser

# List all databases
vkdr postgres listdbs

# When done, clean up
vkdr postgres dropdb -d myapp -u appuser
vkdr postgres remove -d
```

## Formula Examples

### Install Postgres with admin password

```sh
vkdr infra up
vkdr postgres install -p mypassword
```

### Create database with user and password

```sh
vkdr postgres createdb -d mydb -u myuser -p mypassword -s
```

The new "user" will own the new database and be granted all permissions on it. If `-s` is provided the password will be stored in a secret named `myuser-pg-secret`.

### Vault integration

If you have installed Vault, you can use it to generate and store the user's password:

```sh
vkdr vault install
vkdr vault init
vkdr postgres install
vkdr postgres createdb -d mydb -u myuser --vault
```

### External Secrets Operator

When both Vault and ESO are installed, storing the password in a secret relies on the ESO+Vault integration:

```sh
vkdr eso install
vkdr postgres createdb -d mydb -u myuser --vault -s
```
