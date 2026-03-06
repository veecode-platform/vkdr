# VKDR - VeeCode Kubernetes Developer Runtime <!-- omit in toc -->

Também disponível em: 🇺🇸 [English](README.md)

- [Introdução](#introdução)
- [Instalação](#instalação)
- [Executar no shell via Maven](#executar-no-shell-via-maven)
- [Build nativo](#build-nativo)
- [Pasta de fórmulas](#pasta-de-fórmulas)
- [Executando testes](#executando-testes)
- [Publicar Releases](#publicar-releases)
- [Instalando o Java](#instalando-o-java)
- [Atualizando versões das ferramentas](#atualizando-versões-das-ferramentas)
- [Atualizando dependências](#atualizando-dependências)
- [Notas sobre o Maven](#notas-sobre-o-maven)

## Introdução

Esta é uma CLI para acelerar o desenvolvimento local usando Kubernetes sem maiores complicações.

Este projeto usa:

- Spring Boot 4.0.3
- Picocli 4.7.7
- GraalVM Native Support
- Shell scripts (fórmulas)

Cada uma das ações da CLI é implementada por um script shell (fórmula) que é empacotado dentro do binário final. Escolhemos esta estratégia para iterar mais rapidamente em cada nova fórmula.

Exemplo: o comando `infra start` é implementado pelo script `./infra/start/formula.sh` que reside na pasta `src/main/resources/formulas`. Este script é empacotado no binário final e é executado quando o comando `vkdr infra start` é chamado.

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

## Pasta de fórmulas

Durante o desenvolvimento queremos usar as fórmulas diretamente na pasta do projeto (e não as que residem em `~/.vkdr/formulas`). A variável `VKDR_FORMULA_HOME` pode apontar para a pasta `src/main/resources/formulas` deste projeto, o que fará o `vkdr` ignorar o local padrão.

Assim é possível testar mudanças nas fórmulas sem precisar fazer um build binário. O comando abaixo equivale ao `vkdr kong install -h`:

```sh
export VKDR_FORMULA_HOME=$PWD/src/main/resources/formulas
mvn exec:java -Dexec.mainClass=codes.vee.vkdr.VkdrApplication -Dexec.args="kong install -h"
```

## Executando testes

Os testes de fórmulas utilizam BATS (Bash Automated Testing System):

```sh
# Configurar BATS (apenas na primeira vez)
make setup-bats

# Executar todos os testes (requer cluster ativo)
make test

# Executar testes de fórmulas específicas
make test-whoami
make test-kong
make test-postgres
```

## Publicar Releases

O pipeline deste projeto irá gerar um novo release com os assets binários de cada plataforma suportada sempre que um "tagged push" ocorrer em main.

- vkdr-linux-amd64
- vkdr-linux-arm64
- vkdr-osx-amd64
- vkdr-osx-arm64

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

Recomendo usar o SDKMAN (<https://sdkman.io/install>) para instalar
a JDK localmente. Para este projeto utilizamos a GraalVM 25:

```shell
sdk install java 25.0.2-graalce
```

## Atualizando versões das ferramentas

O VKDR baixa e gerencia várias ferramentas CLI (kubectl, helm, k3d, etc.). Para atualizar as versões fixadas para os releases mais recentes:

```sh
make update-tools-versions
```

Este script busca as versões mais recentes nos releases do GitHub e atualiza o arquivo `_shared/lib/tools-versions.sh`. Execute periodicamente para manter as versões das ferramentas atualizadas.

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

Warnings de unsafe memory access podem ser suprimidos por enquanto com:

```shell
export MAVEN_OPTS="--enable-native-access=ALL-UNNAMED --sun-misc-unsafe-memory-access=allow"
```
