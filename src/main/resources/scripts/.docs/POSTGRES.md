# Postgres formula <!-- omit in toc -->

This formula installs a Postgres database on a Kubernetes cluster with several possible configurations.

- [Install Postgres with admin password](#install-postgres-with-admin-password)
- [Creates a new database, user and password](#creates-a-new-database-user-and-password)


## Install Postgres with admin password

```sh
# starts cluster
vkdr infra up
# starts Postgres
vkdr postgres install -p mypassword
```

## Creates a new database, user and password

```sh
vkdr createdb -d mydb -u myuser -p mypassword -s
```

The new "user" will own the new database and be granted all permissions on it. If `-s` is provided the `password` will be stored in a known secret named `myuser-pg-secret` (replace "myuser" by actual user name provided in `-u`).
