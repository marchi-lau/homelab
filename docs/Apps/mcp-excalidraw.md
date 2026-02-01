# MCP Excalidraw

Excalidraw MCP server for AI-controlled diagram creation, exposed via Tailscale for private access.

## Quick Links

- **Canvas UI**: https://excalidraw-mcp.marchi.app (Public)
- **MCP Server**: https://mcp-excalidraw.tailb1bee0.ts.net/sse (Tailscale only)
- **GitHub**: https://github.com/yctimlin/mcp_excalidraw
- **Supergateway**: https://github.com/supercorp-ai/supergateway

---

## Deployment Info

| Property | Value |
|----------|-------|
| Namespace | `mcp-excalidraw` |
| Canvas Image | `ghcr.io/yctimlin/mcp_excalidraw-canvas:latest` |
| MCP Server | `node:22-alpine` + supergateway + yctimlin/mcp_excalidraw |
| Canvas Port | 3000 |
| MCP Port | 8000 |
| Canvas Ingress | Cloudflare Tunnel (public) |
| MCP Ingress | Tailscale (private) |
| Transport | SSE (via Supergateway) |

---

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────────────────────────┐
│ Claude Code │────►│  Tailscale   │────►│  K8s Pod (mcp-excalidraw)           │
│ (mcp-remote)│     │  Mesh        │     │                                     │
└─────────────┘     └──────────────┘     │  ┌─────────────────────────────┐    │
                                         │  │ Container: mcp-server       │    │
                                         │  │ ┌─────────────────────────┐ │    │
                                         │  │ │ Supergateway (port 8000)│ │    │
                                         │  │ │ SSE ← stdio bridge      │ │    │
                                         │  │ └───────────┬─────────────┘ │    │
                                         │  │             │ stdio         │    │
                                         │  │ ┌───────────▼─────────────┐ │    │
                                         │  │ │ MCP Server              │ │    │
                                         │  │ │ (yctimlin/mcp_excalidraw│ │    │
                                         │  │ └───────────┬─────────────┘ │    │
                                         │  └─────────────┼───────────────┘    │
                                         │                │ REST API           │
                                         │  ┌─────────────▼───────────────┐    │
                                         │  │ Container: canvas           │    │
                                         │  │ (port 3000)                 │    │
                                         │  │ Excalidraw UI + REST API    │    │
                                         │  └─────────────────────────────┘    │
                                         └─────────────────────────────────────┘
                                                          │
                                                          │ Cloudflare Tunnel
                                                          ▼
                                         ┌─────────────────────────────────────┐
                                         │  https://excalidraw-mcp.marchi.app  │
                                         │  (Public Canvas UI)                 │
                                         └─────────────────────────────────────┘
```

The MCP server connects to the canvas via localhost REST API. Supergateway bridges the stdio-based MCP server to HTTP/SSE transport for remote access.

---

## Claude Code Configuration

Add to `~/.claude.json` or project `.mcp.json`:

```json
{
  "mcpServers": {
    "mcp-excalidraw": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp-excalidraw.tailb1bee0.ts.net/sse"]
    }
  }
}
```

**Note:** Requires Tailscale connection to access the MCP server.

---

## Capabilities

The Excalidraw MCP server provides tools for:

- **create_rectangle**: Create rectangles on the canvas
- **create_ellipse**: Create ellipses/circles
- **create_diamond**: Create diamond shapes
- **create_text**: Add text elements
- **create_arrow**: Draw arrows between elements
- **create_line**: Draw lines
- **update_element**: Modify existing elements
- **delete_element**: Remove elements from canvas
- **group_elements**: Group multiple elements
- **align_elements**: Align elements
- **create_from_mermaid**: Convert Mermaid diagrams to Excalidraw

---

## Resource Limits

```yaml
# Canvas container
resources:
  requests:
    memory: "128Mi"
    cpu: "50m"
  limits:
    memory: "512Mi"
    cpu: "500m"

# MCP server container
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

---

## Commands

```bash
# Check pod status
kubectl get pods -n mcp-excalidraw

# View canvas logs
kubectl logs -n mcp-excalidraw deployment/mcp-excalidraw -c canvas

# View MCP server logs
kubectl logs -n mcp-excalidraw deployment/mcp-excalidraw -c mcp-server

# Restart deployment
kubectl rollout restart deployment/mcp-excalidraw -n mcp-excalidraw

# Check ingresses
kubectl get ingress -n mcp-excalidraw
```

---

## Troubleshooting

### MCP server not connecting

1. Check the MCP server container logs:
   ```bash
   kubectl logs -n mcp-excalidraw deployment/mcp-excalidraw -c mcp-server --tail=50
   ```

2. Verify supergateway is running:
   ```bash
   kubectl logs -n mcp-excalidraw deployment/mcp-excalidraw -c mcp-server | grep supergateway
   ```

3. Test SSE endpoint directly:
   ```bash
   curl -s --max-time 5 https://mcp-excalidraw.tailb1bee0.ts.net/sse
   ```

### Canvas not loading

1. Check canvas container:
   ```bash
   kubectl logs -n mcp-excalidraw deployment/mcp-excalidraw -c canvas
   ```

2. Test canvas URL:
   ```bash
   curl -sI https://excalidraw-mcp.marchi.app
   ```

### Build failures (OOM)

The MCP server builds from source on startup. If it fails with OOM:
- Only `build:server` is run (not frontend) to save memory
- Increase memory limits if needed

---

## Security Notes

- **Canvas UI**: Public access via Cloudflare Tunnel (view-only for unauthenticated users)
- **MCP Server**: Private access via Tailscale mesh network
- **TLS**: Automatic via Cloudflare (public) and Tailscale (private)
- **No secrets**: MCP server connects to canvas via localhost, no API keys needed

---

## Related

- [[../Homelab|Homelab Overview]]
- [[../Network/Tailscale-Operator|Tailscale Operator Setup]]
- [[../Network/Cloudflare-Tunnel|Cloudflare Tunnel (Public Ingress)]]
- [[mcp-cloudflare|MCP Cloudflare]]

## Tags

#app #mcp #excalidraw #diagrams #tailscale #cloudflare
