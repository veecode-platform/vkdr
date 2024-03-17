# VKDR - Vertigo Kubernetes Developer Runtime <!-- omit in toc -->

- [Introdução](#introdução)
- [Executar no shell](#executar-no-shell)
- [Build nativo](#build-nativo)

## Introdução

Esta é uma CLI para acelerar o desenvolvimento local usando Kubernetes sem maiores complicações.

Este projeto usa:

- Spring Boot 3.1.9
- Picoli 4.7.5
- GraalVM Native Support

## Executar no shell

Para executar a CLI no shell (via Maven):
```sh
mvn exec:java -Dexec.mainClass=codes.vee.vkdr.VkdrApplication -Dexec.args="infra up"
```

## Build nativo

Para compilar o projeto gerando binário nativo:
```sh
./mvnw native:compile -Pnative
```

Para executar o binário nativo gerado:
```sh
./target/vkdr
```

