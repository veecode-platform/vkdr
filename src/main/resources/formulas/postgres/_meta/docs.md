# Postgres formula <!-- omit in toc -->

This formula installs a Postgres database on a Kubernetes cluster with several possible configurations.

- [Install Postgres with admin password](#install-postgres-with-admin-password)
- [Creates a new database, user and password](#creates-a-new-database-user-and-password)
- [Vault integration](#vault-integration)
- [External Secrets Operator](#external-secrets-operator)


## Install Postgres with admin password

```sh
# starts cluster
vkdr infra up
# starts Postgres
vkdr postgres install -p mypassword
```

## Creates a new database, user and password

```sh
vkdr postgres createdb -d mydb -u myuser -p mypassword -s
```

The new "user" will own the new database and be granted all permissions on it. If `-s` is provided the `password` will be stored in a known secret named `myuser-pg-secret` (replace "myuser" by actual user name provided in `-u`).

## Vault integration

If you have installed Vault, you can use it generate and store the user's password. 
This is done by providing the `--create-vault` flag:

```sh
vkdr vault install
vkdr vault init
vkdr postgres install
vkdr postgres createdb -d mydb -u myuser --create-vault
```

## External Secrets Operator

At several points in VKDR Vault is integrated with the External Secrets Operator. If you have installed both of them, "storing" the password in a secret will rely on the ESO+Vault integration.

```sh
vkdr eso install
vkdr postgres createdb -d mydb -u myuser --create-vault -s
```
