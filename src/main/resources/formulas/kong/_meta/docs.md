# Kong formula <!-- omit in toc -->

This formula installs Kong API Gateway on a Kubernetes cluster with several possible configurations.

- [Kong OSS in db-less mode](#kong-oss-in-db-less-mode)
- [Kong OSS in standard (traditional) mode](#kong-oss-in-standard-traditional-mode)
- [Kong OSS in standard (traditional) mode with a shared database](#kong-oss-in-standard-traditional-mode-with-a-shared-database)
- [Kong OSS in standard (traditional) mode with a custom domain (good for remote use)](#kong-oss-in-standard-traditional-mode-with-a-custom-domain-good-for-remote-use)
- [Kong Enterprise in standard (traditional) mode as a secondary Ingress Controller](#kong-enterprise-in-standard-traditional-mode-as-a-secondary-ingress-controller)
- [Kong Enterprise in standard (traditional) mode with custom domain](#kong-enterprise-in-standard-traditional-mode-with-custom-domain)
- [Kong custom image in standard (traditional) mode (custom plugins)](#kong-custom-image-in-standard-traditional-mode-custom-plugins)


## Kong OSS in db-less mode

```sh
# starts cluster
vkdr infra up
# starts Kong
vkdr kong install
```

- Kong: http://localhost:8000
- Kong Manager: http://manager.localhost:8000/manager
- Kong Admin API: http://manager.localhost:8000

## Kong OSS in standard (traditional) mode

```sh
# starts cluster
vkdr infra up
# starts Kong
vkdr kong install -m standard
```

- Kong: http://localhost:8000
- Kong Manager: http://manager.localhost:8000/manager
- Kong Admin API: http://manager.localhost:8000

A Postgres database is also deployed in the cluster automatically, passwords are generated randomly.

## Kong OSS in standard (traditional) mode with a shared database

```sh
# starts cluster
vkdr infra up
# starts shared database and creates kong user
vkdr postgres install
vkdr postgres createdb -d kong -u kong -p kong -s
# starts Kong
vkdr kong install -m standard
```

- Kong: http://localhost:8000
- Kong Manager: http://manager.localhost:8000/manager
- Kong Admin API: http://manager.localhost:8000

The "kong" database user's password is kept in a secret named `kong-pg-secret` ("kong install" will detect and refer to it by name).

## Kong OSS in standard (traditional) mode with a custom domain (good for remote use)

```sh
# starts cluster
vkdr infra start --http 80 --https 443
# starts Kong
vkdr kong install -m standard -d mydomain.com -s
```

- Kong: ports 80 and 443 in hosts' public IP address
- Kong Manager: https://manager.mydomain.com/manager
- Kong Admin API: https://manager.mydomain.com

Making "manager.mydomain.com" resolve to the public IP address of the host is required for this configuration to work.

Please notice that the `-d` domain flag is a suffix for "manager.DOMAIN" endpoints for Kong Manager and Admin API, **but when using this flag you are expected to use ports 80/443 as per above.** The `-s` flag will generate tls ingresses that will result in self-signed certificates (default behaviour).

## Kong Enterprise in standard (traditional) mode as a secondary Ingress Controller

```sh
# starts cluster
vkdr infra start --traefik --nodeports=2 # nodeports 30000/30001 exposed as 9000/9001
# starts Kong
vkdr kong install -e -l /full_path/license.json -m standard -p mypassword --use-nodeport
```

- Kong: http://localhost:8000
- Kong Manager: http://manager.localhost:8000/manager
- Kong Admin API: http://manager.localhost:8000

There are two ingress controllers in this example - Traefik as the default in 8000/8001 and Kong in 9000/9001. The `--use-nodeport` flag in `vkdr` starts Kong in nodeports 30000/30001 (exposed as 9000/9001). This addresses the common need to split Manager/Admin API trafic from the default gateway ports.

If `-l /full_path/license.json` is not provided together with `-e` then Kong will start in "free mode". If both `-e` and `-l` are provided, a valid license will enable Kong RBAC and both Kong Manager and Admin API will require authentication (user "kong_admin", password as informed in `-p`).

**Important**: using "-e" changes the ingressClass used by Manager and Admin API from "kong" to an empty string "" (meaning the cluster's default).

## Kong Enterprise in standard (traditional) mode with custom domain

```sh
# starts cluster
vkdr infra start --http 80 --https 443
# starts Kong
vkdr kong install -e -l /full_path/license.json -m standard -p mypassword --default-ic -d mydomain.com -s
```

- Kong: http://localhost and https://localhost (self-signed) 
- Kong Manager: https://manager.mydomain.com/manager
- Kong Admin API: https://manager.mydomain.com

Kong is the default (and only) ingress controller of the cluster. Both `-e` and `-l` enable RBAC (user "kong_admin").

## Kong custom image in standard (traditional) mode (custom plugins)

```sh
# starts cluster
vkdr infra up
# starts Kong
vkdr kong install -m standard -i veecode/kong-cred -t 3.6.1-r1 --env "plugins=bundled,oidc,oidc-acl,mtls-auth,mtls-acl,late-file-log"
```

- Kong: http://localhost:8000
- Kong Manager: http://manager.localhost:8000/manager
- Kong Admin API: http://manager.localhost:8000

The env variable enables plugins on the custom image. The custom image is pulled from Docker Hub.
