# Exemplos VKDR <!-- omit in toc -->

- [Iniciar cluster local](#iniciar-cluster-local)
- [Iniciar cluster local com Traefik em portas arbitrárias](#iniciar-cluster-local-com-traefik-em-portas-arbitrárias)
- [Instalar Postgres e criar databases/users separados](#instalar-postgres-e-criar-databasesusers-separados)
- [Instalar Kong (com database)](#instalar-kong-com-database)
- [Instalar Kong (com database)](#instalar-kong-com-database-1)
- [Instalar Keycloak e importar uma realm de exemplo](#instalar-keycloak-e-importar-uma-realm-de-exemplo)
- [Instalar Kong e Keycloak como OIDC provider da Admin UI](#instalar-kong-e-keycloak-como-oidc-provider-da-admin-ui)
- [Comandos "explain"](#comandos-explain)

## Iniciar cluster local

Inicia um cluster local usando k3d. Não há ingress controller instalado por default.

```sh
vkdr infra up
```

Assim que um serviço LoadBalancer (como um ingress controller) for instalado ele estará disponível no host nas portas 8000 e 8001 (http/https).

## Iniciar cluster local com Traefik em portas arbitrárias

Inicia um cluster local já com Traefik ingress controller exposto em portas específicas:

```sh
vkdr infra start --http 80 --https 443 --traefik
```

## Instalar Postgres e criar databases/users separados

Instala Postgres e cria alguns databases e usuários:

```sh
vkdr infra up
vkdr postgres install -p senhadb
vkdr postgres createdb -d banco -u user -p senha -s
vkdr postgres createdb -d outrobanco -u outrouser -p outrasenha -s
```

Uma secret `user-pg-secret` será criada com as credenciais do novo usuário.

## Instalar Kong (com database)

Instala Kong Gateway (e ingress controller) com Postgres como database:

```sh
vkdr infra up
vkdr kong install -m standard --default-ic
```

Kong Manager em http://manager.localhost:8000/manager.

## Instalar Kong (com database)

Instala Kong Gateway (e ingress controller) com database compartilhado:

```sh
vkdr infra up
vkdr postgres install
vkdr postgres createdb -d kong -u kong -p kongpwd -s
vkdr kong install -m standard --default-ic
```

A fórmula `kong install` instala o Kong Gateway e utiliza o database `kong` (ao detectar a secret `kong-pg-secret`).

## Instalar Keycloak e importar uma realm de exemplo

```sh
vkdr infra start --traefik
vkdr keycloak install -p admin
vkdr keycloak import -f /path/to/realm-export.json
```

Keycloak em http://auth.localhost:8000/.

## Instalar Kong e Keycloak como OIDC provider da Admin UI

Instalação mais complexa:

- Roda cluster com Traefik em portas 80 e 443 (default ingress controller)
- Instala Postgres e cria databases para Kong e Keycloak.
- Instala Keycloak e importa uma realm de exemplo.
- Instala Kong Gateway com Keycloak como OIDC provider da Admin UI (e ingress controller via nodeport).

Pré-requisitos:

- Arquivo de realm exportado de Keycloak
- Arquivo de licença do Kong

```sh
vkdr infra start --http 80 --https 443
vkdr postgres install
vkdr postgres createdb -d kong -u kong -p kongpwd -s
vkdr kong install -e -l /full_path/license.json -m standard --default-ic -d localdomain -s
vkdr postgres createdb -d keycloak -u keycloak -p keycloakpwd -s
vkdr keycloak install -d localdomain -s
vkdr keycloak import -f $(pwd)/samples/realm-export.json
# testar ambos no browser antes de ligar OIDC
vkdr kong install -e -l /full_path/license.json -m standard --oidc --default-ic -d localdomain -s
```



```sh
vkdr infra start --http 80 --https 443 --traefik --nodeports=2
vkdr postgres install
vkdr postgres createdb -d keycloak -u keycloak -p keycloakpwd -s
vkdr keycloak install
vkdr keycloak import -f $(pwd)/samples/realm-export.json
vkdr postgres createdb -d kong -u kong -p kongpwd -s --drop
vkdr kong install -e -l /full_path/license.json -m standard --oidc --use-nodeport
```

## Comandos "explain"

Algumas fórmulas possuem comandos `explain` que detalham diversos cenários de uso:

```sh
vkdr kong explain
```
                                        