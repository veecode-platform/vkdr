# Postgres formula <!-- omit in toc -->

This formula installs an opinionated Vault server. This is meant to be integrated with all other formulas so that no secrets are stored anywhere else, and kubernets secrets are mantained by Vault itself.

- [Install Vault in Dev Mode](#install-vault-in-dev-mode)
- [Install Vault in Production Mode](#install-vault-in-production-mode)
- [Read and Decode Vault Keys](#read-and-decode-vault-keys)
- [External Secrets Operator](#external-secrets-operator)

## Install Vault in Dev Mode

Vault can be installed in "dev" mode with a custom root token. This means that you don't need to initialize or unseal it. This is useful for development and testing purposes.

```sh
# starts cluster with traefik
vkdr infra start --traefik
# starts Postgres
vkdr vault install --dev --dev-root-token mysecret
```

Vault UI: http://vault.localhost:8000

## Install Vault in Production Mode

Vault is installed in production mode by default. This means that you need to initialize and unseal it (using the "init" formula).

Please notice that "ïnit" operation takes care of both Vault initialization and unsealing. This is a one-time operation, but you can run it more than once (it will exit quietly).

```sh
# starts cluster
vkdr infra start --traefik
# Vault install and init
vkdr vault install -s
vkdr vault init
```

This behaviour is possible because we are keeping the unseal keys in a kubernetes secret. This is not the most secure way to do it, but it is the most practical one (VKDR is not designed for production use anyway). 

## Read and Decode Vault Keys

To read and decode the root and unseal Vault keys you can use the following command:

```sh
kubectl get secret vault-keys -n vkdr -o jsonpath='{.data}' | \
  jq -r 'to_entries[] | "\(.key)=\(.value | @base64d)"'
```

Please understand that this is VKDR-specific and should not be used in production. This is just a way to make it easier to work with Vault in a development environment.

## External Secrets Operator

At several points in VKDR Vault is integrated with the External Secrets Operator. You have to install them in any order:

```sh
vkdr infra start --traefik
vkdr vault install -s
vkdr vault init
vkdr eso install
```

