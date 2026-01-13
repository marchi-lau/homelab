# Service Specification: MCP Cloudflare Service

> Spec Number: 015
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/mcp-cloudflare.yaml

## Overview

MCP Cloudflare is a Model Context Protocol (MCP) server that provides Claude and other AI assistants with tools to interact with Cloudflare APIs. Exposed via Tailscale for private access. Uses supergateway to bridge STDIO-based MCP to HTTP.

## Service Requirements

### SR-1: Cloudflare API Access
- **Need:** AI assistants need Cloudflare management capabilities
- **Solution:** MCP server wrapping @cloudflare/mcp-server-cloudflare
- **Verification:** `curl -s https://mcp-cloudflare.<tailnet>.ts.net/sse`

### SR-2: Private Access Only
- **Need:** Security-sensitive API should not be public
- **Solution:** Tailscale ingress with TLS
- **Verification:** Only accessible via Tailscale network

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `mcp-cloudflare` |
| Image | `node:20-alpine` |
| Replicas | 1 |
| Strategy | RollingUpdate |

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 128Mi | 512Mi |
| CPU | 50m | 500m |

### Health Probes

| Probe | Type | Port | Path | Initial Delay |
|-------|------|------|------|---------------|
| Readiness | TCP | 8000 | N/A | 45s |
| Liveness | TCP | 8000 | N/A | 60s |

## Networking

| Property | Value |
|----------|-------|
| Service Type | ClusterIP |
| Port | 8000 |
| Ingress Class | tailscale |
| Public URL | N/A |
| Private URL | https://mcp-cloudflare.<tailnet>.ts.net |

## Storage

| Property | Value |
|----------|-------|
| Storage Class | none |
| Size | N/A |
| Mount Path | N/A |
| Access Mode | N/A |

## Configuration

### Container Command

```sh
npm install -g supergateway @cloudflare/mcp-server-cloudflare &&
supergateway --stdio "npx -y @cloudflare/mcp-server-cloudflare run <account-id>" --port 8000 --host 0.0.0.0
```

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| CLOUDFLARE_API_TOKEN | (from secret) | Cloudflare authentication |

### Secrets

| Secret | Keys | Purpose |
|--------|------|---------|
| mcp-cloudflare-credentials | CLOUDFLARE_API_TOKEN | Cloudflare API token |

## Dependencies

### Requires
- Cloudflare API token with appropriate permissions
- Tailscale operator
- Flux GitOps

### Required By
- Claude Code / MCP clients

## Operations

### Status Check
```bash
kubectl get pods -n mcp-cloudflare
kubectl logs -n mcp-cloudflare -l app=mcp-cloudflare --tail=50
```

### Update API Token
```bash
kubectl edit secret mcp-cloudflare-credentials -n mcp-cloudflare
kubectl rollout restart deployment/mcp-cloudflare -n mcp-cloudflare
```

### Restart
```bash
kubectl rollout restart deployment/mcp-cloudflare -n mcp-cloudflare
```

### Update
1. Edit `clusters/homelab/apps/mcp-cloudflare.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### Pod takes long to start
- **Symptom:** Pod stays in ContainerCreating for 60s+
- **Cause:** npm install running on every startup
- **Fix:** Expected behavior; consider building custom image

### API calls failing
- **Symptom:** MCP tools return errors
- **Cause:** Invalid or expired Cloudflare API token
- **Fix:** Update CLOUDFLARE_API_TOKEN in secret

## Related

- Docs: [[docs/Apps/mcp-cloudflare.md]]
- External: https://github.com/cloudflare/mcp-server-cloudflare

## Tags

#homelab #k8s #mcp #cloudflare #api #tailscale
