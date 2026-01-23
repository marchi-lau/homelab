# Cloudflare Tunnel Setup

Expose K3s services to the internet via Cloudflare Tunnel without opening ports.

## Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Internet      │────►│  Cloudflare Edge │────►│  cloudflared    │
│                 │     │  (WAF, SSL, CDN) │     │  (K8s pod)      │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                              HTTPS                       │
                                                          ▼
                                                 ┌─────────────────┐
                                                 │  K8s Service    │
                                                 │  (ClusterIP)    │
                                                 └─────────────────┘
```

**Benefits:**
- No open ports on firewall
- Free SSL certificates
- DDoS protection
- WAF (Web Application Firewall)
- Cloudflare Access for authentication

---

## Current Configuration

| Property | Value |
|----------|-------|
| Tunnel Name | homelab-k3s |
| Controller | cloudflare-tunnel-ingress-controller |
| Namespace | cloudflare-tunnel-ingress-controller |
| Account ID | c7dea80c850b959ae89d2757244db1d0 |

### Exposed Services

| Host | Service | Namespace |
|------|---------|-----------|
| n8n-02.marchi.app | n8n:5678 | n8n |

---

## How It Works

1. **Ingress Controller** watches for Ingress resources with `ingressClassName: cloudflare-tunnel`
2. **Controller** creates/updates Cloudflare Tunnel configuration via API
3. **cloudflared** pod maintains outbound connection to Cloudflare edge
4. **Traffic flow:** Internet → Cloudflare → Tunnel → K8s Service

---

## Installation

### Prerequisites

- Cloudflare account
- Domain on Cloudflare
- API Token with permissions:
  - `Zone:Zone:Read`
  - `Zone:DNS:Edit`
  - `Account:Cloudflare Tunnel:Edit`

### Install via Helm

```bash
# Add repo
helm repo add strrl.dev https://helm.strrl.dev
helm repo update

# Install (credentials not stored in git)
KUBECONFIG=~/.kube/config-s740 helm upgrade --install --wait \
  -n cloudflare-tunnel-ingress-controller --create-namespace \
  cloudflare-tunnel-ingress-controller \
  strrl.dev/cloudflare-tunnel-ingress-controller \
  --set=cloudflare.apiToken="<API_TOKEN>" \
  --set=cloudflare.accountId="<ACCOUNT_ID>" \
  --set=cloudflare.tunnelName="homelab-k3s"
```

---

## Expose a Service

### 1. Create Service (ClusterIP)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: myapp
spec:
  type: ClusterIP  # Not NodePort!
  ports:
    - port: 8080
      targetPort: 8080
  selector:
    app: myapp
```

### 2. Create Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  namespace: myapp
spec:
  ingressClassName: cloudflare-tunnel
  rules:
    - host: myapp.marchi.app
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myapp
                port:
                  number: 8080
```

### 3. Deploy

```bash
git add . && git commit -m "deploy: myapp" && git push
flux reconcile kustomization apps --with-source
```

The controller will:
- Create DNS CNAME record for `myapp.marchi.app`
- Configure tunnel routing
- Traffic starts flowing automatically

---

## Verify

```bash
# Check controller
kubectl get pods -n cloudflare-tunnel-ingress-controller

# Check ingresses
kubectl get ingress -A

# Check tunnel connections
kubectl logs -n cloudflare-tunnel-ingress-controller \
  -l app.kubernetes.io/name=controlled-cloudflared-connector --tail=20

# Test access
curl -I https://myapp.marchi.app
```

---

## Troubleshooting

### 403 Forbidden (Cloudflare Block)

If you see "Sorry, you have been blocked":

1. Go to Cloudflare Dashboard → marchi.app
2. Security → WAF → Custom rules
3. Create exception rule:
   - Field: `Hostname`
   - Operator: `equals`
   - Value: `myapp.marchi.app`
   - Action: `Skip` (all)

### Tunnel Not Connecting

```bash
# Check cloudflared logs
kubectl logs -n cloudflare-tunnel-ingress-controller \
  -l app.kubernetes.io/name=controlled-cloudflared-connector

# Check controller logs
kubectl logs -n cloudflare-tunnel-ingress-controller \
  -l app.kubernetes.io/name=cloudflare-tunnel-ingress-controller
```

### DNS Not Resolving

```bash
# Check if CNAME was created
dig myapp.marchi.app

# Should show CNAME to *.cfargotunnel.com
```

---

## Security: Cloudflare Access

To add authentication (SSO) to a service:

1. Cloudflare Dashboard → Zero Trust → Access → Applications
2. Add Application → Self-hosted
3. Configure:
   - Application domain: `myapp.marchi.app`
   - Identity providers: Google, GitHub, etc.
   - Policies: Who can access

---

## Rotate Credentials

If API token is compromised:

1. Revoke old token in Cloudflare Dashboard
2. Create new token
3. Update Helm release:

```bash
KUBECONFIG=~/.kube/config-s740 helm upgrade \
  -n cloudflare-tunnel-ingress-controller \
  cloudflare-tunnel-ingress-controller \
  strrl.dev/cloudflare-tunnel-ingress-controller \
  --set=cloudflare.apiToken="<NEW_TOKEN>" \
  --set=cloudflare.accountId="c7dea80c850b959ae89d2757244db1d0" \
  --set=cloudflare.tunnelName="homelab-k3s"
```

---

## Uninstall

```bash
# Remove Helm release
helm uninstall cloudflare-tunnel-ingress-controller \
  -n cloudflare-tunnel-ingress-controller

# Delete namespace
kubectl delete namespace cloudflare-tunnel-ingress-controller

# Clean up in Cloudflare Dashboard:
# - Zero Trust → Networks → Tunnels → Delete tunnel
# - DNS → Delete CNAME records
```

---

## Related

- [[Homelab|Homelab Dashboard]]
- [[Apps/n8n|n8n App]]
- [[Runbooks/Quick-Commands|Quick Commands]]

## Tags

#homelab #cloudflare #tunnel #ingress #security
