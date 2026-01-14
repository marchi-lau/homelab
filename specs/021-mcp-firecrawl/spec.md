# Service Specification: MCP Firecrawl Server

> Spec Number: 021
> Created: 2026-01-14
> Status: Deployed
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
| Startup | TCP | 3000 | N/A | 10s (30 retries) |
| Readiness | TCP | 3000 | N/A | N/A |
| Liveness | TCP | 3000 | N/A | N/A |

Note: MCP endpoints require specific protocol headers and don't support simple HTTP health checks.

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
| HOST | `0.0.0.0` | Bind to all interfaces (required for K8s) |
| FIRECRAWL_API_URL | `http://firecrawl.firecrawl.svc.cluster.local:3002` | Internal K8s service endpoint |
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

## Implementation Notes (2026-01-14)

### Files Created
| File | Purpose |
|------|---------|
| `clusters/homelab/apps/mcp-firecrawl.yaml` | K8s deployment, service, and Tailscale ingress |
| `specs/021-mcp-firecrawl/spec.md` | This specification |

### Bug Fixes Applied During Implementation
- **Issue:** Server bound to `::1:3000` (localhost only), causing probe failures
  - **Fix:** Added `HOST=0.0.0.0` environment variable
- **Issue:** HTTP health probes returned 400/406 (MCP requires specific headers)
  - **Fix:** Changed to TCP probes
- **Issue:** npm install takes ~50s, causing liveness probe failures
  - **Fix:** Added startupProbe with 30 retries (5 minutes tolerance)
- **Issue:** Pod can't resolve Tailscale DNS for Firecrawl backend
  - **Fix:** Use internal K8s service URL instead of Tailscale hostname

### Related Commits
- `1609f2d` feat(mcp-firecrawl): deploy MCP server for Firecrawl web scraping API
- `cf19b33` fix(mcp-firecrawl): add startupProbe for slow npm install
- `92f3367` fix(mcp-firecrawl): use TCP probes instead of HTTP
- `15c7a0d` fix(mcp-firecrawl): bind to 0.0.0.0 for k8s pod access

## Tags

#homelab #k8s #mcp #firecrawl #tailscale #web-scraping #ai
