# Tailscale Operator

Private ingress for internal services via Tailscale mesh network.

## Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Your Devices   │────►│  Tailscale Mesh  │────►│  K8s Service    │
│  (tailnet)      │     │  (encrypted)     │     │  (private)      │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

**Use Cases:**
- Private MCP servers
- Internal admin dashboards
- Development/staging environments
- Services not meant for public internet

---

## Current Configuration

| Property | Value |
|----------|-------|
| Operator Version | v1.92.4 |
| Namespace | `tailscale` |
| IngressClass | `tailscale` |
| Default Tag | `tag:kubernetes` |
| OAuth Client | `krqoaeLikZ11CNTRL` |

---

## Comparison with Cloudflare Tunnel

| Feature | Cloudflare Tunnel | Tailscale |
|---------|-------------------|-----------|
| Access | Public internet | Tailnet only |
| Auth | Cloudflare Access | Tailscale ACLs |
| DNS | `*.marchi.app` | `*.tail<xxxxx>.ts.net` |
| Use case | Public apps | Private/internal |
| TLS | Cloudflare certs | Auto (90-day) |

---

## Installation

### Prerequisites

1. Tailscale account
2. OAuth client with scopes:
   - `devices` (Write)
   - `auth_keys` (Write)
3. ACL tag configured:
   ```json
   {
     "tagOwners": {
       "tag:kubernetes": ["autogroup:admin"]
     }
   }
   ```

### Install via Helm

```bash
# Add repo
helm repo add tailscale https://pkgs.tailscale.com/helmcharts
helm repo update

# Install (credentials not stored in git)
KUBECONFIG=~/.kube/config-s740 helm upgrade --install tailscale-operator tailscale/tailscale-operator \
  -n tailscale --create-namespace \
  --set oauth.clientId="<OAUTH_CLIENT_ID>" \
  --set oauth.clientSecret="<OAUTH_CLIENT_SECRET>" \
  --set operatorConfig.defaultTags="{tag:kubernetes}"
```

---

## Expose a Private Service

### 1. Create Service (ClusterIP)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-mcp-server
  namespace: mcp
spec:
  type: ClusterIP
  ports:
    - port: 8080
      targetPort: 8080
  selector:
    app: my-mcp-server
```

### 2. Create Tailscale Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-mcp-server
  namespace: mcp
spec:
  ingressClassName: tailscale  # ← Private access only
  rules:
    - host: my-mcp-server      # Becomes my-mcp-server.<tailnet>.ts.net
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-mcp-server
                port:
                  number: 8080
```

### 3. Deploy

```bash
kubectl apply -f my-mcp-server.yaml

# Check Tailscale proxy
kubectl get pods -n tailscale
```

The service will be accessible at: `https://my-mcp-server.<tailnet>.ts.net`

---

## Verify

```bash
# Check operator
kubectl get pods -n tailscale

# Check IngressClass
kubectl get ingressclass

# View Tailscale devices
# https://login.tailscale.com/admin/machines

# Check operator logs
kubectl logs -n tailscale -l app.kubernetes.io/name=tailscale-operator
```

---

## Troubleshooting

### Operator in Error/CrashLoop

```bash
# Check logs
kubectl logs -n tailscale deployment/operator

# Common issues:
# - "not enough permissions" → Update OAuth scopes
# - "tags invalid" → Add tag to ACLs
```

### Service Not Accessible

```bash
# Check ingress status
kubectl get ingress -A

# Check Tailscale proxy pod
kubectl get pods -n tailscale -l tailscale.com/parent-resource-type=ingress

# Check proxy logs
kubectl logs -n tailscale -l tailscale.com/parent-resource-type=ingress
```

### Rotate Credentials

```bash
# Create new OAuth client in Tailscale admin
# Then upgrade Helm release:
KUBECONFIG=~/.kube/config-s740 helm upgrade tailscale-operator tailscale/tailscale-operator \
  -n tailscale \
  --set oauth.clientId="<NEW_CLIENT_ID>" \
  --set oauth.clientSecret="<NEW_CLIENT_SECRET>" \
  --set operatorConfig.defaultTags="{tag:kubernetes}"
```

---

## Uninstall

```bash
# Remove Helm release
helm uninstall tailscale-operator -n tailscale

# Delete namespace
kubectl delete namespace tailscale

# Remove devices from Tailscale admin:
# https://login.tailscale.com/admin/machines
```

---

## Related

- [[Cloudflare-Tunnel|Cloudflare Tunnel]] - Public ingress
- [[../Homelab|Homelab Overview]]

## Tags

#homelab #tailscale #ingress #private #mcp
