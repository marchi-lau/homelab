# Service Specification: RSSHub Feed Generator

> Spec Number: 013
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/rsshub.yaml

## Overview

RSSHub is an open-source RSS feed generator that creates RSS feeds from various sources including social media, forums, and websites that don't natively support RSS. Includes Chromium for JavaScript-rendered pages.

## Service Requirements

### SR-1: RSS Feed Generation
- **Need:** Generate RSS feeds from non-RSS sources
- **Solution:** RSSHub with extensive route support
- **Verification:** `curl -s https://rsshub.marchi.app`

### SR-2: JavaScript Rendering
- **Need:** Handle dynamic content requiring browser rendering
- **Solution:** Chromium-bundled image
- **Verification:** Test route requiring JS rendering

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `rsshub` |
| Image | `diygod/rsshub:chromium-bundled` |
| Replicas | 1 |
| Strategy | RollingUpdate |

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 256Mi | 1Gi |
| CPU | 100m | 1000m |

### Health Probes

| Probe | Type | Port | Path | Initial Delay |
|-------|------|------|------|---------------|
| N/A | N/A | N/A | N/A | N/A |

## Networking

| Property | Value |
|----------|-------|
| Service Type | ClusterIP |
| Port | 1200 |
| Ingress Class | cloudflare-tunnel |
| Public URL | https://rsshub.marchi.app |

## Storage

| Property | Value |
|----------|-------|
| Storage Class | none |
| Size | N/A |
| Mount Path | N/A |
| Access Mode | N/A |

## Configuration

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| NODE_ENV | `production` | Runtime environment |
| CACHE_EXPIRE | `3600` | Cache TTL in seconds |
| LISTEN_INADDR_ANY | `1` | Listen on all interfaces |

### Secrets

| Secret | Keys | Purpose |
|--------|------|---------|
| N/A | N/A | No secrets required |

## Dependencies

### Requires
- Cloudflare Tunnel operator
- Flux GitOps

### Required By
- Homepage dashboard (displays link)
- Miniflux (can consume generated feeds)

## Operations

### Status Check
```bash
kubectl get pods -n rsshub
kubectl logs -n rsshub -l app=rsshub --tail=50
```

### Restart
```bash
kubectl rollout restart deployment/rsshub -n rsshub
```

### Update
1. Edit `clusters/homelab/apps/rsshub.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### High memory usage
- **Symptom:** Pod OOM killed during Chromium operations
- **Cause:** Heavy JS rendering routes
- **Fix:** Increase memory limits, reduce concurrent requests

### Feed returns empty
- **Symptom:** Route returns no items
- **Cause:** Source changed or rate limited
- **Fix:** Check RSSHub issues for route updates

## Related

- External: https://docs.rsshub.app/

## Tags

#homelab #k8s #rss #feeds #scraping
