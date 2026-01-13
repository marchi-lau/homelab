# Service Specification: Uptime Kuma Monitoring

> Spec Number: 007
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/uptime-kuma.yaml

## Overview

Uptime Kuma is a self-hosted monitoring tool for tracking the availability of websites, APIs, and services. It provides status pages, alerting, and historical uptime data. Used to monitor homelab services and external dependencies.

## Service Requirements

### SR-1: Service Monitoring
- **Need:** Track availability of services and endpoints
- **Solution:** HTTP/HTTPS/TCP/DNS monitoring with configurable intervals
- **Verification:** `curl -s https://status.marchi.app`

### SR-2: Status Page
- **Need:** Public status page for service visibility
- **Solution:** Built-in status page feature
- **Verification:** `curl -s https://status.marchi.app/status/<page>`

### SR-3: Persistent History
- **Need:** Historical uptime data across restarts
- **Solution:** 1Gi PVC on local-path storage
- **Verification:** `kubectl get pvc -n uptime-kuma`

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `uptime-kuma` |
| Image | `louislam/uptime-kuma:1` |
| Replicas | 1 |
| Strategy | Recreate |

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 128Mi | 256Mi |
| CPU | 50m | 500m |

### Health Probes

| Probe | Type | Port | Path | Initial Delay |
|-------|------|------|------|---------------|
| N/A | N/A | N/A | N/A | N/A |

## Networking

| Property | Value |
|----------|-------|
| Service Type | ClusterIP |
| Port | 3001 |
| Ingress Class | cloudflare-tunnel |
| Public URL | https://status.marchi.app |

## Storage

| Property | Value |
|----------|-------|
| Storage Class | local-path |
| Size | 1Gi |
| Mount Path | /app/data |
| Access Mode | ReadWriteOnce |

## Configuration

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| N/A | N/A | Default configuration |

### Secrets

| Secret | Keys | Purpose |
|--------|------|---------|
| N/A | N/A | Credentials configured in UI |

## Dependencies

### Requires
- local-path storage class
- Cloudflare Tunnel operator
- Flux GitOps

### Required By
- Homepage dashboard (displays link)
- n8n (webhook notifications)

## Operations

### Status Check
```bash
kubectl get pods -n uptime-kuma
kubectl logs -n uptime-kuma -l app=uptime-kuma --tail=50
```

### Restart
```bash
kubectl rollout restart deployment/uptime-kuma -n uptime-kuma
```

### Update
1. Edit `clusters/homelab/apps/uptime-kuma.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### Database locked
- **Symptom:** Error messages about SQLite lock
- **Cause:** Concurrent access issues
- **Fix:** Restart pod, ensure single replica

## Related

- Docs: [[docs/Apps/uptime-kuma.md]]
- External: https://github.com/louislam/uptime-kuma

## Tags

#homelab #k8s #monitoring #uptime #status
