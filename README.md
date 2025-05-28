# VKDR - Vertigo Kubernetes Developer Runtime <!-- omit in toc -->

- [Introdução](#introdução)
- [Instalação](#instalação)
- [Executar no shell via Maven](#executar-no-shell-via-maven)
- [Build nativo](#build-nativo)
- [Pasta de scripts](#pasta-de-scripts)
- [Publicar Releases](#publicar-releases)
- [Instalando o Java](#instalando-o-java)

## Introdução

Esta é uma CLI para acelerar o desenvolvimento local usando Kubernetes sem maiores complicações.

Este projeto usa:

- Spring Boot 3.1.9
- Picoli 4.7.6
- GraalVM Native Support
- Shell scripts

Cada uma das ações da CLI é implementada por um script shell que é empacotado dentro do binário final. Escolhemos esta estratégia para iterar mais rapidamente em cada nova fórmula.

Exemplo: o comando `infra start` é implementado pelo script `./infra/start/formula.sh` que reside na pasta `src/main/resources/scripts`. Este script é empacotado no binário final e é executado quando o comando `vkdr infra start` é chamado.

## Instalação

Para instalar esta CLI:

```sh
curl -L get-vkdr.vee.codes | bash
```

## Executar no shell via Maven

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

## Pasta de scripts

Durante o desenvolvimento queremos usar os scripts diretamente na pasta do projeto (e não os que residem em `~/.vkdr/scripts`). A variável `VKDR_SCRIPT_HOME` pode apontar para a pasta `src/main/resources/scripts` deste projeto, o que fará o `vkdr` ignorar o local padrão.

Assim é possível testar mudanças nos scripts sem precisar fazer um build binário. O comando abaixo equivale ao `vkdr kong install -h`:

```sh
mvn exec:java -Dexec.mainClass=codes.vee.vkdr.VkdrApplication -Dexec.args="kong install -h"
```

## Publicar Releases

O pipeline deste projeto irá gerar um novo release com os assets binários de cada plataforma suportada sempre que um "tagged push" ocorrer em main.

* vkdr-linux-amd64
* vkdr-osx-amd64
* vkdr-osx-arm64

Para fazer um tagged push e gerar um release manualmente:

```shell
git tag -a v1.0.x -m "v1.0.x"
git push --tags
```

Para gerar release por automação definimos a versão na forma tradicional do Maven (x.y.z-SNAPSHOT) e o `Makefile` possui uma task que automatiza a task inteira (inclusive o "bump" de versão):

```shell
make release
```

Para uma versão na POM definida como "x.y.z-SNAPSHOT" será feito:

- Commit de versão "x.y.z"
- Tag "vx.y.z" ("v" como prefixo)
- Push (com a tag), o que dispara o pipeline da release no Github
- Commit/push de versão "x.y.z+1-SNAPSHOT"

## Instalando o Java

Recomendo usar o SDKMAN (https://sdkman.io/install) para instalar
a JDK localmente. Para este projeto utilizamos a GraalVM 21:

```shell
sdk use java 24.0.1-graalce
```

## Atualizando dependências

Verificar dependências com:

```shell
mvn versions:display-dependency-updates
```

Verificar plugins com:

```shell
mvn versions:display-plugin-updates
```

## Notas sobre o Maven

Warnings de unsafe memory access podem ser suspendidos por enquanto com:

```shell
export MAVEN_OPTS="--enable-native-access=ALL-UNNAMED --sun-misc-unsafe-memory-access=allow"
```
