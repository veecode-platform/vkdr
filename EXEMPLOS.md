# Exemplos VKDR <!-- omit in toc -->

- [Iniciar cluster local](#iniciar-cluster-local)
- [Iniciar cluster local com Traefik em portas arbitrárias](#iniciar-cluster-local-com-traefik-em-portas-arbitrárias)
- [Instalar Postgres e criar databases/users separados](#instalar-postgres-e-criar-databasesusers-separados)
- [Instalar Kong (com database)](#instalar-kong-com-database)
- [Instalar Kong (com database)](#instalar-kong-com-database-1)
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

## Instalar Kong (com database)

Instala Kong Gateway (e ingress controller) com database compartilhado:

```sh
vkdr infra up
vkdr postgres install
vkdr postgres createdb -d kong -u kong -p kongpwd -s
vkdr kong install -m standard --default-ic
```

A fórmula `kong install` instala o Kong Gateway e utiliza o database `kong` (ao detectar a secret `kong-pg-secret`).

## Comandos "explain"

Algumas fórmulas possuem comandos `explain` que detalham diversos cenários de uso:

```sh
vkdr kong explain
```


