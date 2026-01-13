# Service Specification: Webhook.site

> Spec Number: 019
> Created: 2026-01-14
> Status: Planned
> Manifest: clusters/homelab/apps/webhook-site.yaml

## Overview

Webhook.site is a self-hosted webhook testing and debugging tool. It provides a unique URL to receive HTTP requests and webhooks, allowing inspection, transformation, and forwarding of incoming data. Useful for API development, webhook debugging, and integration testing.

## Service Requirements

### SR-1: Webhook Testing Interface
- **Need:** Ability to receive and inspect webhooks/HTTP requests
- **Solution:** Webhook.site web UI with unique endpoint generation
- **Verification:** `curl https://webhook.marchi.app`

### SR-2: Public Access
- **Need:** Webhook endpoints must be publicly accessible
- **Solution:** Cloudflare Tunnel ingress
- **Verification:** Access https://webhook.marchi.app from external network

### SR-3: Request Persistence
- **Need:** Store received webhooks for review
- **Solution:** Redis for caching and SQLite for persistence
- **Verification:** Received webhooks visible in UI after refresh

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `webhook-site` |
| Image | `webhooksite/webhook.site:latest` |
| Replicas | 1 |
| Strategy | RollingUpdate |

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 128Mi | 512Mi |
| CPU | 100m | 500m |

### Health Probes

| Probe | Type | Port | Path | Initial Delay |
|-------|------|------|------|---------------|
| Readiness | HTTP | 80 | / | 10s |
| Liveness | HTTP | 80 | / | 30s |

## Networking

| Property | Value |
|----------|-------|
| Service Type | ClusterIP |
| Port | 80 |
| Ingress Class | cloudflare-tunnel |
| Public URL | https://webhook.marchi.app |
| Private URL | N/A |

## Storage

| Property | Value |
|----------|-------|
| Storage Class | local-path |
| Size | 1Gi |
| Mount Path | /var/www/html/storage |
| Access Mode | ReadWriteOnce |

## Configuration

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| APP_ENV | `production` | Laravel environment |
| APP_DEBUG | `false` | Disable debug mode |
| APP_URL | `https://webhook.marchi.app` | Application URL |
| APP_LOG | `errorlog` | Logging method |
| DB_CONNECTION | `sqlite` | Database driver |
| REDIS_HOST | `webhook-site-redis` | Redis hostname |
| BROADCAST_DRIVER | `redis` | Real-time broadcasting |
| QUEUE_DRIVER | `redis` | Queue backend |
| CACHE_DRIVER | `redis` | Cache backend |

### Secrets

| Secret | Keys | Purpose |
|--------|------|---------|
| webhook-site-secrets | app-key | Laravel APP_KEY for encryption |

## Dependencies

### Requires
- Redis (deployed as sidecar or separate pod)
- Cloudflare Tunnel operator
- Flux GitOps

### Required By
- None (end-user tool)

## Operations

### Status Check
```bash
kubectl get pods -n webhook-site
kubectl logs -n webhook-site -l app=webhook-site --tail=50
```

### Restart
```bash
kubectl rollout restart deployment/webhook-site -n webhook-site
```

### Update
1. Edit `clusters/homelab/apps/webhook-site.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### Webhooks not persisting
- **Symptom:** Received webhooks disappear after pod restart
- **Cause:** SQLite database not on persistent storage
- **Fix:** Ensure PVC mounted at /var/www/html/storage

### Redis connection errors
- **Symptom:** 500 errors or slow performance
- **Cause:** Redis sidecar not running or misconfigured
- **Fix:** Check Redis container logs, verify REDIS_HOST env var

## Related

- External: https://github.com/webhooksite/webhook.site
- Docs: https://docs.webhook.site/

## Tags

#homelab #k8s #webhook #testing #api #cloudflare-tunnel
