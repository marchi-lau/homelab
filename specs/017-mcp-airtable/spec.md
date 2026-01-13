# Service Specification: MCP Airtable Service

> Spec Number: 017
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/mcp-airtable.yaml

## Overview

MCP Airtable is a Model Context Protocol (MCP) server providing AI assistants with Airtable database capabilities. Built from source with automatic updates when the upstream repository changes. Features GitRepository watching and CronJob-based auto-restart.

## Service Requirements

### SR-1: Airtable API Access
- **Need:** AI assistants need Airtable database capabilities
- **Solution:** MCP server with full Airtable API support
- **Verification:** `curl -s https://mcp-airtable.<tailnet>.ts.net/sse`

### SR-2: Automatic Updates
- **Need:** Stay current with upstream changes
- **Solution:** Flux GitRepository + CronJob auto-restart
- **Verification:** `kubectl get gitrepository -n mcp-airtable`

### SR-3: Private Access
- **Need:** MCP services should be private
- **Solution:** Tailscale ingress with TLS
- **Verification:** Only accessible via Tailscale network

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `mcp-airtable` |
| Image | `node:20-alpine` |
| Replicas | 1 |
| Strategy | Recreate |

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 256Mi | 512Mi |
| CPU | 100m | 500m |

### Health Probes

| Probe | Type | Port | Path | Initial Delay |
|-------|------|------|------|---------------|
| Startup | TCP | 3000 | N/A | 90s |
| Readiness | TCP | 3000 | N/A | 5s |
| Liveness | TCP | 3000 | N/A | 5s |

## Networking

| Property | Value |
|----------|-------|
| Service Type | ClusterIP |
| Port | 3000 |
| Ingress Class | tailscale |
| Public URL | N/A |
| Private URL | https://mcp-airtable.<tailnet>.ts.net |

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
apk add --no-cache git &&
git clone https://github.com/delta-and-beta/mcp-airtable.git /app &&
cd /app &&
npm install --include=dev &&
npm run build &&
npm start
```

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| PORT | `3000` | Application port |
| HOST | `0.0.0.0` | Listen address |
| NODE_ENV | `production` | Runtime environment |

### Node Affinity

| Type | Expression | Purpose |
|------|------------|---------|
| preferredDuringSchedulingIgnoredDuringExecution | hostname=k3s-node-01 | Prefer worker node |

### RBAC

| Resource | Purpose |
|----------|---------|
| ServiceAccount | deployment-restarter |
| Role | Get/patch deployments, gitrepositories, configmaps |
| RoleBinding | Bind role to service account |

### CronJob

| Schedule | Purpose |
|----------|---------|
| */5 * * * * | Check upstream for changes, restart if needed |

### Secrets

| Secret | Keys | Purpose |
|--------|------|---------|
| N/A | N/A | API keys passed by client |

## Dependencies

### Requires
- Flux source-controller (for GitRepository)
- Tailscale operator
- Flux GitOps

### Required By
- Claude Code / MCP clients

## Operations

### Status Check
```bash
kubectl get pods -n mcp-airtable
kubectl get gitrepository -n mcp-airtable
kubectl logs -n mcp-airtable -l app=mcp-airtable --tail=50
```

### Check Auto-Update Status
```bash
kubectl get configmap mcp-airtable-revision -n mcp-airtable -o yaml
kubectl logs -n mcp-airtable -l job-name --tail=20
```

### Force Update
```bash
kubectl delete configmap mcp-airtable-revision -n mcp-airtable
kubectl rollout restart deployment/mcp-airtable -n mcp-airtable
```

### Restart
```bash
kubectl rollout restart deployment/mcp-airtable -n mcp-airtable
```

### Update
1. Edit `clusters/homelab/apps/mcp-airtable.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### Pod takes very long to start
- **Symptom:** Pod stays in ContainerCreating for 2+ minutes
- **Cause:** npm install and build on every startup
- **Fix:** Expected behavior; startupProbe has 90s initialDelay

### Auto-update not working
- **Symptom:** New upstream commits not triggering restarts
- **Cause:** GitRepository not syncing or CronJob failing
- **Fix:** Check GitRepository status, CronJob logs

## Related

- Docs: [[docs/WIP/mcp-airtable-transport-fix.md]]
- External: https://github.com/delta-and-beta/mcp-airtable

## Tags

#homelab #k8s #mcp #airtable #api #tailscale #automation
