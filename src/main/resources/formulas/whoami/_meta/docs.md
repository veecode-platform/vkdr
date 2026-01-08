# vkdr whoami

Use these commands to install and manage a sample `whoami` application to test cluster ingress behavior.

The whoami service is a simple HTTP server that returns information about the request and the container it's running in. It's useful for testing ingress configuration, load balancing, and debugging network issues.

## vkdr whoami install

Install the whoami test service in your cluster.

```bash
vkdr whoami install [-s] [-d=<domain>] [--gateway=<class>] [--label=<String=String>]...
```

### Flags

| Flag | Shorthand | Description | Default |
|------|-----------|-------------|---------|
| `--domain` | `-d` | Domain name for the generated ingress/route | `localhost` |
| `--secure` | `-s` | Enable HTTPS | `false` |
| `--gateway` | | Use Gateway API instead of Ingress. Specify the GatewayClass name. | (none) |
| `--label` | | Custom labels for whoami resources (repeatable) | (none) |

### Routing: Ingress vs Gateway API

By default, whoami uses **Ingress** for HTTP routing. You can optionally use the **Gateway API** by specifying a gateway class:

- **Ingress (default)**: Works with ingress controllers like nginx-ingress or traefik
- **Gateway API**: Works with Gateway API implementations like NGINX Gateway Fabric

### Examples

#### Basic Installation (with Ingress)

```bash
vkdr infra up
vkdr nginx install --default-ic
vkdr whoami install
curl http://whoami.localhost:8000
```

#### Using Gateway API

```bash
vkdr infra up
vkdr nginx-gw install
vkdr whoami install --gateway nginx
curl http://whoami.localhost:8000
```

#### With Custom Domain

```bash
vkdr whoami install -d myapp.local
curl http://myapp.local:8000
```

#### With HTTPS

```bash
vkdr whoami install -s
curl -k https://whoami.localhost:8001
```

#### With Custom Labels

Add labels for service mesh integration or monitoring:

```bash
vkdr whoami install --label app=test --label version=v1
```

## vkdr whoami remove

Remove the whoami service from your cluster.

```bash
vkdr whoami remove
```

### Example

```bash
vkdr whoami remove
```

## vkdr whoami explain

Explain whoami service setup and configuration options.

```bash
vkdr whoami explain
```

## Complete Examples

### Testing Ingress Controllers

Test different ingress controllers with whoami:

```bash
# Start cluster
vkdr infra up

# Test with NGINX Ingress Controller
vkdr nginx install --default-ic
vkdr whoami install
curl http://whoami.localhost:8000
vkdr whoami remove
vkdr nginx remove

# Test with Traefik
vkdr traefik install --default-ic
vkdr whoami install
curl http://whoami.localhost:8000
vkdr whoami remove
vkdr traefik remove
```

### Testing with Gateway API

```bash
# Start cluster
vkdr infra up

# Install NGINX Gateway Fabric
vkdr nginx-gw install

# Install whoami using Gateway API
vkdr whoami install --gateway nginx
curl http://whoami.localhost:8000

# Clean up
vkdr whoami remove
vkdr nginx-gw remove
```

### Testing Load Balancing

Scale the whoami deployment to test load balancing:

```bash
vkdr infra up
vkdr nginx install --default-ic
vkdr whoami install

# Scale to multiple replicas
kubectl scale deployment whoami -n vkdr --replicas=3

# Make multiple requests to see different pod responses
for i in {1..10}; do curl -s http://whoami.localhost:8000 | grep Hostname; done

# Clean up
vkdr whoami remove
```

## Response Format

The whoami service returns useful debugging information:

```
Hostname: whoami-6d5b9b9c9f-abc12
IP: 10.42.0.15
RemoteAddr: 10.42.0.1:54321
GET / HTTP/1.1
Host: whoami.localhost:8000
User-Agent: curl/7.79.1
Accept: */*
X-Forwarded-For: 10.42.0.1
X-Forwarded-Host: whoami.localhost:8000
X-Forwarded-Port: 80
X-Forwarded-Proto: http
X-Real-Ip: 10.42.0.1
```

This information helps verify:
- Which pod is handling the request (Hostname)
- Request headers are being passed correctly
- Ingress/Gateway proxy headers are set properly

## Resources Created

- **Namespace**: `vkdr`
- **Deployment**: `whoami` (1 replica)
- **Service**: `whoami` (ClusterIP, port 80)
- **Ingress**: `whoami` (when using Ingress mode)
- **HTTPRoute**: `whoami` (when using Gateway API mode)

## Helm Chart

Uses the [cowboysysop/whoami](https://github.com/cowboysysop/charts/tree/master/charts/whoami) Helm chart (version 6.0.0).
