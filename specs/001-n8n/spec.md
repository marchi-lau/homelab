# Service Specification: n8n Workflow Automation

> Spec Number: 001
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/n8n.yaml

## Overview

n8n is a self-hosted workflow automation platform that enables building complex automations through a visual node-based interface. It provides a low-code way to integrate various services and automate repetitive tasks. The homelab deployment runs behind Tailscale for secure private access.

## Service Requirements

### SR-1: Workflow Automation
- **Need:** Visual workflow builder for automating tasks across services
- **Solution:** n8n provides node-based editor with 400+ integrations
- **Verification:** `kubectl get pods -n n8n && curl -s https://n8n.tailb1bee0.ts.net`

### SR-2: Persistent Data Storage
- **Need:** Workflows and credentials must survive pod restarts
- **Solution:** 5Gi PVC on synology-nfs with fix-permissions init container
- **Verification:** `kubectl get pvc -n n8n`

### SR-3: Webhook Support
- **Need:** External services can trigger workflows via HTTP
- **Solution:** Webhook URL configured via WEBHOOK_URL environment variable
- **Verification:** `curl -X POST https://n8n.tailb1bee0.ts.net/webhook-test/<id>`

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `n8n` |
| Image | `n8nio/n8n:latest` |
| Replicas | 1 |
| Strategy | Recreate |

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 256Mi | 1Gi |
| CPU | 100m | 1000m |

### Health Probes

| Probe | Type | Port | Path | Initial Delay |
|-------|------|------|------|---------------|
| Readiness | N/A | N/A | N/A | N/A |
| Liveness | N/A | N/A | N/A | N/A |

## Networking

| Property | Value |
|----------|-------|
| Service Type | ClusterIP |
| Port | 5678 |
| Ingress Class | tailscale |
| Public URL | N/A |
| Private URL | https://n8n.tailb1bee0.ts.net |

## Storage

| Property | Value |
|----------|-------|
| Storage Class | synology-nfs |
| Size | 5Gi |
| Mount Path | /home/node/.n8n |
| Access Mode | ReadWriteOnce |

## Configuration

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| N8N_HOST | `0.0.0.0` | Listen on all interfaces |
| N8N_PORT | `5678` | Application port |
| N8N_PROTOCOL | `http` | Internal protocol |
| NODE_ENV | `production` | Runtime environment |
| WEBHOOK_URL | `https://n8n.tailb1bee0.ts.net/` | External webhook base URL |
| GENERIC_TIMEZONE | `Asia/Hong_Kong` | Timezone for scheduling |
| N8N_PROXY_HOPS | `1` | Proxy headers handling |

### Init Containers

| Container | Image | Purpose |
|-----------|-------|---------|
| fix-permissions | busybox:1.36 | Fix NFS permissions for non-root user (1000:1000) |

### Secrets

| Secret | Keys | Purpose |
|--------|------|---------|
| N/A | N/A | No secrets required |

## Dependencies

### Requires
- synology-nfs storage class
- Tailscale operator
- Flux GitOps

### Required By
- Homepage dashboard (displays n8n status)
- Uptime Kuma (monitors n8n availability)

## Operations

### Status Check
```bash
kubectl get pods -n n8n
kubectl logs -n n8n -l app=n8n --tail=50
```

### Restart
```bash
kubectl rollout restart deployment/n8n -n n8n
```

### Update
1. Edit `clusters/homelab/apps/n8n.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### Pod stuck in CrashLoopBackOff
- **Symptom:** Pod continuously restarts
- **Cause:** NFS permission issues or corrupted data
- **Fix:** Check init container logs, verify NFS mount permissions

### Webhooks not receiving requests
- **Symptom:** External services cannot trigger workflows
- **Cause:** WEBHOOK_URL misconfigured or Tailscale ACL blocking
- **Fix:** Verify WEBHOOK_URL matches Tailscale hostname, check ACLs

## Related

- Docs: [[docs/Apps/n8n.md]]
- External: https://docs.n8n.io/

## Tags

#homelab #k8s #automation #workflow #n8n
