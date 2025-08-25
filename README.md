# VKDR - VeeCode Kubernetes Developer Runtime <!-- omit in toc -->

Also available in: 🇧🇷 [Português](README-pt.md)

- [Introduction](#introduction)
- [Installation](#installation)
- [Run in the shell via Maven](#run-in-the-shell-via-maven)
- [Native build](#native-build)
- [Scripts folder](#scripts-folder)
- [Publish Releases](#publish-releases)
- [Installing Java](#installing-java)
- [Updating dependencies](#updating-dependencies)
- [Notes about Maven](#notes-about-maven)

## Introduction

This is a CLI to accelerate local development using Kubernetes without unnecessary complications.

This project uses:

- Spring Boot 3.1.9
- Picoli 4.7.6
- GraalVM Native Support
- Shell scripts

Each CLI action is implemented by a shell script that is packaged inside the final binary. We chose this strategy to iterate faster on each new formula.

Example: the `infra start` command is implemented by the `./infra/start/formula.sh` script that lives in the `src/main/resources/scripts` folder. This script is packaged in the final binary and executed when `vkdr infra start` is invoked.

## Installation

To install this CLI:

```sh
curl -L get-vkdr.vee.codes | bash
```

## Run in the shell via Maven

To run the CLI in the shell (via Maven):

```sh
mvn exec:java -Dexec.mainClass=codes.vee.vkdr.VkdrApplication -Dexec.args="infra up"
```

## Native build

To compile the project and generate a native binary:

```sh
./mvnw native:compile -Pnative
```

To run the generated native binary:

```sh
./target/vkdr
```

## Scripts folder

During development we want to use the scripts directly from the project folder (not the ones under `~/.vkdr/scripts`). The `VKDR_SCRIPT_HOME` variable can point to this project's `src/main/resources/scripts` folder, which will make `vkdr` ignore the default location.

This allows you to test script changes without building a new binary. The command below is equivalent to `vkdr kong install -h`:

```sh
mvn exec:java -Dexec.mainClass=codes.vee.vkdr.VkdrApplication -Dexec.args="kong install -h"
```

## Publish Releases

This project's pipeline will generate a new release with binary assets for each supported platform whenever a tagged push occurs on main.

* vkdr-linux-amd64
* vkdr-linux-arm64
* vkdr-osx-amd64
* vkdr-osx-arm64

To make a tagged push and generate a release manually:

```shell
git tag -a v1.0.x -m "v1.0.x"
git push --tags
```

For automated releases we define the version in Maven's traditional format (x.y.z-SNAPSHOT) and the `Makefile` has a task that automates the entire flow (including the version bump):

```shell
make release
```

For a version in the POM defined as "x.y.z-SNAPSHOT" the following will be done:

- Commit version "x.y.z"
- Tag "vx.y.z" ("v" as prefix)
- Push (with the tag), which triggers the release pipeline on GitHub
- Commit/push version "x.y.z+1-SNAPSHOT"

## Installing Java

I recommend using SDKMAN (https://sdkman.io/install) to install
the JDK locally. For this project we use GraalVM 21:

```shell
sdk install java 24.0.2-graalce
```

## Updating dependencies

Check dependencies with:

```shell
mvn versions:display-dependency-updates
```

Check plugins with:

```shell
mvn versions:display-plugin-updates
```

## Notes about Maven

Unsafe memory access warnings can be suppressed for now with:

```shell
export MAVEN_OPTS="--enable-native-access=ALL-UNNAMED --sun-misc-unsafe-memory-access=allow"
```
