# MCP Cloudflare

Cloudflare MCP server exposed via Tailscale for private access.

## Quick Links

- **URL**: https://mcp-cloudflare.tailb1bee0.ts.net (Tailscale only)
- **GitHub**: https://github.com/cloudflare/mcp-server-cloudflare
- **Supergateway**: https://github.com/supercorp-ai/supergateway

---

## Deployment Info

| Property | Value |
|----------|-------|
| Namespace | `mcp-cloudflare` |
| Image | `node:20-alpine` + supergateway + @cloudflare/mcp-server-cloudflare |
| Port | 8000 |
| Ingress | Tailscale (private) |
| Transport | SSE (via Supergateway) |

---

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────────────────┐
│ Claude Code │────►│  Tailscale   │────►│  K8s Pod                    │
│ (mcp-remote)│     │  Mesh        │     │  ┌───────────────────────┐  │
└─────────────┘     └──────────────┘     │  │ Supergateway          │  │
                                         │  │ (SSE ← stdio bridge)  │  │
                                         │  └───────────┬───────────┘  │
                                         │              │ stdio        │
                                         │  ┌───────────▼───────────┐  │
                                         │  │ @cloudflare/mcp-      │  │
                                         │  │ server-cloudflare     │  │
                                         │  └───────────────────────┘  │
                                         └─────────────────────────────┘
```

Supergateway bridges the stdio-based Cloudflare MCP server to HTTP/SSE transport, enabling remote access via Tailscale.

---

## Claude Code Configuration

Update `.mcp.json` to use the remote server:

```json
{
  "mcpServers": {
    "mcp-cloudflare": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp-cloudflare.tailb1bee0.ts.net/sse"]
    }
  }
}
```

---

## Capabilities

The Cloudflare MCP server provides tools for:

- **Workers**: Deploy, list, and manage Cloudflare Workers
- **KV**: Read/write to KV namespaces
- **D1**: Query D1 databases
- **R2**: Manage R2 storage buckets
- **DNS**: Manage DNS records
- **Cache**: Purge cache
- **Analytics**: Query analytics data

---

## Resource Limits

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "50m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

---

## Commands

```bash
# Check pod status
kubectl get pods -n mcp-cloudflare

# View logs
kubectl logs -n mcp-cloudflare -l app=mcp-cloudflare

# Restart
kubectl rollout restart deployment/mcp-cloudflare -n mcp-cloudflare

# Check Tailscale ingress
kubectl get ingress -n mcp-cloudflare
```

---

## Troubleshooting

### Pod not starting

```bash
# Check events
kubectl describe pod -n mcp-cloudflare -l app=mcp-cloudflare

# Check logs
kubectl logs -n mcp-cloudflare -l app=mcp-cloudflare
```

### Connection refused

1. Verify Tailscale device is connected
2. Check pod is running: `kubectl get pods -n mcp-cloudflare`
3. Verify ingress has address: `kubectl get ingress -n mcp-cloudflare`

### API token issues

```bash
# Verify secret exists
kubectl get secret mcp-cloudflare-credentials -n mcp-cloudflare

# Check token (first 10 chars)
kubectl get secret mcp-cloudflare-credentials -n mcp-cloudflare -o jsonpath='{.data.CLOUDFLARE_API_TOKEN}' | base64 -d | head -c 10
```

---

## Security Notes

- **Private access only**: Only accessible via Tailscale mesh network
- **No public exposure**: Uses `ingressClassName: tailscale`, not `cloudflare-tunnel`
- **API token**: Stored in K8s Secret, not in Git
- **TLS**: Automatic via Tailscale HTTPS certificates

---

## Related

- [[../Homelab|Homelab Overview]]
- [[../Network/Tailscale-Operator|Tailscale Operator Setup]]
- [[../Network/Cloudflare-Tunnel|Cloudflare Tunnel (Public Ingress)]]

## Tags

#app #mcp #cloudflare #tailscale #private
