# AI Draw.io

AI-powered diagram editor based on Draw.io with OpenAI integration.

## Quick Links

- **URL**: https://diagram.marchi.app
- **GitHub**: https://github.com/DayuanJiang/next-ai-draw-io

---

## Deployment Info

| Property | Value |
|----------|-------|
| Namespace | `ai-drawio` |
| Image | `ghcr.io/dayuanjiang/next-ai-draw-io:latest` |
| Port | 3000 |
| Ingress | Cloudflare Tunnel |
| Storage | None (stateless) |

---

## Features

- Full Draw.io diagram editor functionality
- AI-powered diagram generation
- AI diagram suggestions and improvements
- Export to various formats (PNG, SVG, PDF)
- Collaborative editing

---

## Configure OpenAI API Key

The AI features require an OpenAI API key. To configure:

```bash
# Edit the secret
KUBECONFIG=~/.kube/config-s740 kubectl edit secret ai-drawio-config -n ai-drawio

# Change the OPENAI_API_KEY value from "your-api-key-here" to your actual key
# Save and exit

# Restart the deployment to apply
KUBECONFIG=~/.kube/config-s740 kubectl rollout restart deployment/ai-drawio -n ai-drawio
```

Or create a new secret directly:

```bash
KUBECONFIG=~/.kube/config-s740 kubectl create secret generic ai-drawio-config \
  --from-literal=OPENAI_API_KEY=sk-your-actual-key \
  -n ai-drawio \
  --dry-run=client -o yaml | kubectl apply -f -
```

---

## Environment Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `AI_PROVIDER` | `openai` | AI provider (openai) |
| `AI_MODEL` | `gpt-4o` | Model to use |
| `OPENAI_API_KEY` | (secret) | Your OpenAI API key |

---

## Resource Limits

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "50m"
  limits:
    memory: "256Mi"
    cpu: "500m"
```

---

## Commands

```bash
# Check pod status
kubectl get pods -n ai-drawio

# View logs
kubectl logs -n ai-drawio -l app=ai-drawio

# Restart deployment
kubectl rollout restart deployment/ai-drawio -n ai-drawio

# Check secret
kubectl get secret ai-drawio-config -n ai-drawio -o yaml
```

---

## Related

- [[../Homelab|Homelab Overview]]
- [[../Network/Cloudflare-Tunnel|Cloudflare Tunnel Setup]]

## Tags

#app #diagram #ai #drawio #cloudflare
