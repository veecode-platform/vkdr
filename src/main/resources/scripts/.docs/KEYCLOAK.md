# Keycloak formula

This formula installs Keycloak on a Kubernetes cluster with default configurations for local testing and development.

## How to use

```sh
vkdr infra up
vkdr postgres install
vkdr nginx install --default-ic
vkdr keycloak install
```

## Notes

The "install" command will install the Keycloak operator first and then the Keycloak server. If postgres is not present, it will be installed automatically ("postgres install"). The keycloak database will also be installed automatically ("postgres createdb").

The "remove" command will NOT remove the Keycloak operator. It will remove the keycloak server and the keycloak database.
