# VeeCode DevPortal <!-- omit in toc -->

This formula installs VeeCode DevPortal on a Kubernetes cluster with default configurations for local testing and development.

IMPORTANT: currently not working until helm chart is updated.

## Pre-requisites

A few conditions apply:

- You must start `vkdr` bound to ports 80/443 (http/https)
- You must have a valid GitHub PAT token
- You must create entries in your `/etc/hosts` file for the following domains:
    - devportal.localhost (127.0.0.1)
    - petclinic.localhost (127.0.0.1)

```sh
vkdr infra start --http 80 --https 443
export GITHUB_TOKEN=your_github_pat_token
```

## Install DevPortal

The simplest way to install DevPortal is to run the following command:

```sh
vkdr devportal install --github-token $GITHUB_TOKEN
```

This will install DevPortal and its dependencies locally (`vkdr` cluster):

- Kong Gateway (standard mode as as default ingress controller)
- Postgres

DevPortal will be available at http://devportal.localhost, in guest mode and showing e default catalog.

## Install DevPortal with sample applications

You can also deploy sample applications to your cluster by running the following command:

```sh
vkdr devportal install --github-token $GITHUB_TOKEN --samples
```

These sample apps can be used to demonstrate a few live capabilities of DevPortal without needing to build anything yourself. The sample apps are:

- ViaCEP API: a simple API to get Brazilian addresses by CEP.

```sh
curl localhost/cep/20020080/json
```

- Petclinic: a simple Spring Boot application with a few APIs (http://petclinic.localhost/)


## Using your own catalog

You can pick a catalog of youw own just providing its URL:

```sh
vkdr devportal install --github-token $GITHUB_TOKEN --location $YOUR_CATALOG_URL
```

## Using DevPortal to Develop Plugins

You can use DevPortal in conjunction with a local NPM registry to develop dynamic plugins locally.

Start a local NPM registry (like Verdaccio):

```sh
verdaccio -l 0.0.0.0:4873
```

Install DevPortal with the "--npm" argument:

```sh
vkdr devportal install --github-token $GITHUB_TOKEN --npm http://host.k3d.internal:4873
```

Watch verdaccio logs as it caches all downloaded plugins. You can now publish plugins under development to your local registry and they will be available to DevPortal.
