# vkdr crossplane

Use these commands to install and manage the Crossplane runtime in your cluster.

Crossplane is a framework for building cloud-native control planes. It extends Kubernetes with CRDs that let you compose and manage infrastructure resources using the Kubernetes API.

## vkdr crossplane install

Install the Crossplane runtime in your cluster.

```bash
vkdr crossplane install
```

Crossplane is installed into the `crossplane-system` namespace using the stable Helm chart with default values.

### Flags

| Flag | Description | Required |
| --- | --- | --- |
| `--provider` | Crossplane provider to install (`none`, `do`, `aws`) | Yes |
| `--do-token` | API token for DigitalOcean provider | When `--provider do` |
| `--aws-credential-file` | Path to AWS credentials file | When `--provider aws` |

### Examples

Basic install (no provider):

```bash
vkdr infra up
vkdr crossplane install --provider none
```

Install with DigitalOcean provider:

```bash
vkdr crossplane install --provider do --do-token "$DO_TOKEN"
```

Install with AWS provider:

```bash
vkdr crossplane install --provider aws --aws-credential-file ~/.aws/credentials
```

After installation, you can verify the setup:

```bash
kubectl get pods -n crossplane-system
kubectl get providers
```

## vkdr crossplane remove

Remove the Crossplane runtime from your cluster.

```bash
vkdr crossplane remove
```

This removes the Crossplane Helm release and deletes the `crossplane-system` namespace. The operation is idempotent and safe to run multiple times.

### Example

```bash
vkdr crossplane remove
```

## Resources Created

- **Namespace**: `crossplane-system`
- **Helm release**: `crossplane` (from `crossplane-stable/crossplane`)

When a provider is specified, additional resources are created:

- **Provider package**: Installed via Helm `provider.packages` value
- **Secret**: Provider credentials (`provider-do-secret` or `provider-aws-secret`)
- **ProviderConfig**: `default` ProviderConfig CR pointing at the credentials secret

## Helm Chart

Uses the [Crossplane stable Helm chart](https://charts.crossplane.io/stable).
