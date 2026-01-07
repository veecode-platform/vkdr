# vkdr eso

Use these commands to install and manage the External Secrets Operator (ESO) in your `vkdr` cluster.

External Secrets Operator synchronizes secrets from external secret management systems (like HashiCorp Vault, AWS Secrets Manager, etc.) into Kubernetes Secrets.

## vkdr eso install

Install External Secrets Operator in your cluster.

```bash
vkdr eso install
```

### Example

```bash
vkdr infra up
vkdr eso install
```

## vkdr eso remove

Remove External Secrets Operator from your cluster.

```bash
vkdr eso remove
```

### Example

```bash
vkdr eso remove
```

## vkdr eso explain

Explain External Secrets Operator setup and configuration options.

```bash
vkdr eso explain
```

## Complete Examples

### ESO with HashiCorp Vault

The most common use case is syncing secrets from Vault to Kubernetes:

```bash
# Start cluster
vkdr infra up

# Install Vault in dev mode
vkdr vault install --dev

# Install External Secrets Operator
vkdr eso install

# Now you can create ExternalSecret resources that sync from Vault
```

#### Create a SecretStore

After installing ESO, create a SecretStore to connect to Vault:

```yaml
# vault-secret-store.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "http://vault.vault.svc.cluster.local:8200"
      path: "secret"
      version: "v2"
      auth:
        tokenSecretRef:
          name: vault-token
          key: token
```

```bash
kubectl apply -f vault-secret-store.yaml
```

#### Create an ExternalSecret

Sync a secret from Vault to Kubernetes:

```yaml
# my-external-secret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-secret
spec:
  refreshInterval: "1h"
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: my-k8s-secret
  data:
    - secretKey: password
      remoteRef:
        key: secret/data/myapp
        property: password
```

```bash
kubectl apply -f my-external-secret.yaml
# A Kubernetes Secret named 'my-k8s-secret' will be created
```

### ESO with PostgreSQL and Vault

Combine with `vkdr postgres` Vault integration:

```bash
# Start cluster
vkdr infra up

# Install Vault
vkdr vault install --dev

# Install ESO
vkdr eso install

# Install PostgreSQL
vkdr postgres install -w

# Create database with Vault-managed credentials
vkdr postgres createdb -d myapp -u myuser --vault

# Now ESO can sync these database credentials to your application's namespace
```

## How External Secrets Operator Works

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  External       │     │  External       │     │  Kubernetes     │
│  Secret Store   │────>│  Secrets        │────>│  Secret         │
│  (Vault, AWS)   │     │  Operator       │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

1. **SecretStore**: Defines connection to external secret provider
2. **ExternalSecret**: Defines which secrets to sync and how
3. **ESO Controller**: Watches ExternalSecrets and creates/updates Kubernetes Secrets

## Supported Providers

ESO supports many secret providers:

| Provider | Description |
|----------|-------------|
| HashiCorp Vault | Most common with `vkdr vault` |
| AWS Secrets Manager | For AWS environments |
| Azure Key Vault | For Azure environments |
| GCP Secret Manager | For GCP environments |
| Kubernetes | Sync between namespaces |

## Use Cases

- **Centralized secret management**: Store secrets in Vault, sync to multiple clusters
- **Secret rotation**: ESO automatically updates Kubernetes Secrets when source changes
- **Multi-environment**: Same ExternalSecret definition works across dev/staging/prod
- **Compliance**: Keep secrets in approved secret management systems
