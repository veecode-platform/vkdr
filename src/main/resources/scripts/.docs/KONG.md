# Kong formula

This formula installs Kong API Gateway on a Kubernetes cluster with several possible configurations.

## Kong OSS in db-less mode:

```sh
# starts cluster
vkdr infra up
# starts Kong
vkdr kong install
```

- Kong: http://localhost:8000
- Kong Manager: http://manager.localhost:8000/manager
- Kong Admin API: http://manager.localhost:8000

## Kong OSS in stardard (traditional) mode:

```sh
# starts cluster
vkdr infra up
# starts Kong
vkdr kong install -m standard
```

- Kong: http://localhost:8000
- Kong Manager: http://manager.localhost:8000/manager
- Kong Admin API: http://manager.localhost:8000

A Postgres database is also deployed in the cluster automatically.

## Kong OSS in standard (traditional) mode with a shared database:

```sh
# starts cluster
vkdr infra up
# starts database and creates kong user
vkdr postgres install
vkdr postgres createdb -d kong -u kong -p kong -s
# starts Kong
vkdr kong install -m standard
```

- Kong: http://localhost:8000
- Kong Manager: http://manager.localhost:8000/manager
- Kong Admin API: http://manager.localhost:8000

The "kong" database user's password is kept in a known secret ("kong install" will refer to it by name).

## Kong Enterprise in standard (traditional) mode:

```sh
# starts cluster
vkdr infra start --traefik --nodeports=2
# starts Kong
vkdr kong install -e -l /full_path/license.json -m standard
```
