# VeeCode DevPortal <!-- omit in toc -->

This formula installs VeeCode DevPortal on a Kubernetes cluster with default configurations for local testing and development.

## Pre-requisites

A few conditions apply:

- You must start `vkdr` bound to ports 80/443 (http/https)
- You must have a valid GitHub PAT token

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

- Kong Gateway
- Postgres
