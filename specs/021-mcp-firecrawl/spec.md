# Service Specification: MCP Firecrawl Server

> Spec Number: 021
> Created: 2026-01-14
> Status: Planned
> Manifest: clusters/homelab/apps/mcp-firecrawl.yaml

## Overview

MCP Firecrawl Server provides Model Context Protocol access to the self-hosted Firecrawl web scraping API. Enables AI assistants like Claude Code to scrape and crawl web pages, returning clean markdown or structured data for AI workflows.

## Service Requirements

### SR-1: MCP Protocol Access
- **Need:** MCP interface to Firecrawl scraping capabilities
- **Solution:** firecrawl-mcp-server in HTTP Streamable mode
- **Verification:** `curl https://mcp-firecrawl.<tailnet>.ts.net/mcp`

### SR-2: Private Access Only
- **Need:** Service should not be publicly accessible
- **Solution:** Tailscale ingress (no Cloudflare tunnel)
- **Verification:** Only accessible via Tailscale network

### SR-3: Self-Hosted Firecrawl Integration
- **Need:** Connect to existing Firecrawl deployment
- **Solution:** Configure FIRECRAWL_API_URL environment variable
- **Verification:** Scrape endpoint returns content

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `mcp-firecrawl` |
| Image | `node:22-alpine` |
| Replicas | 1 |
| Strategy | Recreate |

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 128Mi | 512Mi |
| CPU | 50m | 500m |

### Health Probes

| Probe | Type | Port | Path | Initial Delay |
|-------|------|------|------|---------------|
| Readiness | HTTP | 3000 | /mcp | 15s |
| Liveness | HTTP | 3000 | /mcp | 30s |

## Networking

| Property | Value |
|----------|-------|
| Service Type | ClusterIP |
| Port | 3000 |
| Ingress Class | tailscale |
| Public URL | N/A |
| Private URL | https://mcp-firecrawl.<tailnet>.ts.net |

## Storage

| Property | Value |
|----------|-------|
| Storage Class | N/A |
| Size | N/A |
| Mount Path | N/A |
| Access Mode | N/A |

## Configuration

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| HTTP_STREAMABLE_SERVER | `true` | Enable HTTP Streamable mode |
| FIRECRAWL_API_URL | `https://firecrawl.tailb1bee0.ts.net` | Self-hosted Firecrawl endpoint |
| NODE_ENV | `production` | Node environment |

### Secrets

| Secret | Keys | Purpose |
|--------|------|---------|
| N/A | N/A | Self-hosted Firecrawl doesn't require API key |

## Dependencies

### Requires
- Firecrawl API (spec 020) at `firecrawl.tailb1bee0.ts.net`
- Tailscale operator
- Flux GitOps

### Required By
- Claude Code (MCP client)
- Other MCP-compatible AI assistants

## Operations

### Status Check
```bash
kubectl get pods -n mcp-firecrawl
kubectl logs -n mcp-firecrawl -l app=mcp-firecrawl --tail=50
```

### Test MCP Endpoint
```bash
curl https://mcp-firecrawl.<tailnet>.ts.net/mcp
```

### Restart
```bash
kubectl rollout restart deployment/mcp-firecrawl -n mcp-firecrawl
```

### Update
1. Edit `clusters/homelab/apps/mcp-firecrawl.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### MCP endpoint not responding
- **Symptom:** Connection refused or timeout
- **Cause:** Server not started or Tailscale issue
- **Fix:** Check pod logs, verify Tailscale ingress

### Firecrawl API errors
- **Symptom:** MCP returns errors when scraping
- **Cause:** Firecrawl service unavailable
- **Fix:** Check Firecrawl pod status: `kubectl get pods -n firecrawl`

### npx/npm errors
- **Symptom:** Container fails to start
- **Cause:** npm package not found or network issue
- **Fix:** Check container logs for npm errors

## Related

- Spec 020: Firecrawl (backend API)
- External: https://github.com/firecrawl/firecrawl-mcp-server

## Tags

#homelab #k8s #mcp #firecrawl #tailscale #web-scraping #ai
