---
trigger: always_on
---

# Introduction
VKDR is a command-line interface (CLI) tool designed to accelerate local development using Kubernetes without unnecessary complications.

# Technical Stack:
- Spring Boot
- Picocli (CLI framework)
- GraalVM Native Support (for native binary compilation)
- Shell scripts

# Command Structure: The CLI offers various commands to manage different services:
- infra: Manages the Kubernetes infrastructure (start, stop, up, down, expose)
- kong: API Gateway management
- postgres: Database management
- vault: Secrets management
- nginx: Web server

# Packages and Folders
- Java base package name is "codes.vee.vkdr"
- CLI Commands are defined in annotated Java classes (Picocli framework). The command defines a Java package under "src/main/java", and the subcommand defines the Java class name. So "vkdr infra start" defines the "codes.vee.vkdr.infra" package, a base "VkdrInfraCommand" class and the "VkdrInfraStartCommand" class (as a subcommand from VkdrInfraCommand)
- Every command and subcommands defined in Picocli will also depend on folders under "src/main/resources/scripts"
- So "vkdr infra start" runs "src/main/resources/scripts/infra/start/formula.sh"
- The main script for a command is always "formula.sh" and commandline options defined for a command become script args too

# Command-line options
- A CommandLine.Option defined for a command will become a shell script argument.
- Some commands (specially the ones that install/remove tools) have a common set of arguments that define a hostname and a boolean "secure". For those we use a special field "@CommandLine.Mixin private CommonDomainMixin domainSecure;"

# Explain command
- For some commands we define a "explain" subcommand, that uses a "glow" CLI to open a markdown document. The commands "kong explain" and "mirror explain" are examples, use them as a reference to create others when asked.