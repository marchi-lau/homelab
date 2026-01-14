# Service Specification: Firecrawl Web Scraping API

> Spec Number: 020
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/firecrawl.yaml

## Overview

Firecrawl is a self-hosted web scraping and crawling API that converts web pages into clean markdown or structured data for AI applications. Deployed as an internal service accessible only via Tailscale, it provides LLM-ready web content extraction capabilities.

## Service Requirements

### SR-1: Web Scraping API
- **Need:** API to crawl/scrape web pages and return clean content
- **Solution:** Firecrawl API with Playwright browser automation
- **Verification:** `curl https://firecrawl.<tailnet>.ts.net/` returns JSON response

### SR-2: Private Access Only
- **Need:** Service should not be publicly accessible
- **Solution:** Tailscale ingress (no Cloudflare tunnel)
- **Verification:** Only accessible via Tailscale network

### SR-3: Browser Automation
- **Need:** Handle JavaScript-heavy pages
- **Solution:** Playwright service for headless browser rendering
- **Verification:** Check playwright container logs

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `firecrawl` |
| Image (API) | `ghcr.io/firecrawl/firecrawl:latest` |
| Image (Playwright) | `ghcr.io/firecrawl/playwright-service:latest` |
| Replicas | 1 |
| Strategy | Recreate |

### Resources

| Container | Memory Request | Memory Limit | CPU Request | CPU Limit |
|-----------|----------------|--------------|-------------|-----------|
| API | 512Mi | 2Gi | 200m | 2000m |
| Playwright | 512Mi | 2Gi | 200m | 1000m |
| Redis | 64Mi | 256Mi | 50m | 200m |
| RabbitMQ | 128Mi | 512Mi | 100m | 500m |
| PostgreSQL | 128Mi | 512Mi | 100m | 500m |

### Health Probes

| Probe | Type | Port | Path | Initial Delay |
|-------|------|------|------|---------------|
| Readiness | HTTP | 3002 | / | 60s |
| Liveness | HTTP | 3002 | / | 90s |

## Networking

| Property | Value |
|----------|-------|
| Service Type | ClusterIP |
| Port | 3002 |
| Ingress Class | tailscale |
| Public URL | N/A |
| Private URL | https://firecrawl.<tailnet>.ts.net |

## Storage

| Property | Value |
|----------|-------|
| Storage Class | synology-nfs |
| Size | 5Gi |
| Mount Path | /var/lib/postgresql/data |
| Access Mode | ReadWriteOnce |

## Configuration

### Environment Variables (API)

| Variable | Value | Purpose |
|----------|-------|---------|
| PORT | `3002` | API port |
| HOST | `0.0.0.0` | Listen address |
| REDIS_URL | `redis://localhost:6379` | Redis connection |
| RABBITMQ_URL | `amqp://localhost:5672` | RabbitMQ connection |
| PLAYWRIGHT_MICROSERVICE_URL | `http://localhost:3000` | Playwright service |
| POSTGRES_HOST | `localhost` | Database host |
| POSTGRES_PORT | `5432` | Database port |
| POSTGRES_USER | `firecrawl` | Database user |
| POSTGRES_PASSWORD | (from secret) | Database password |
| POSTGRES_DB | `firecrawl` | Database name |
| DATABASE_URL | (constructed) | Full connection string |

### Secrets

| Secret | Keys | Purpose |
|--------|------|---------|
| firecrawl-secrets | postgres-password, bull-auth-key | Database and admin credentials |

## Dependencies

### Requires
- Tailscale operator
- synology-nfs storage class
- Flux GitOps

### Required By
- AI workflows (n8n, MCP clients)
- Claude Code / AI assistants

## Operations

### Status Check
```bash
kubectl get pods -n firecrawl
kubectl logs -n firecrawl -l app=firecrawl -c firecrawl-api --tail=50
```

### Test API
```bash
curl -X POST https://firecrawl.<tailnet>.ts.net/v0/scrape \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'
```

### Restart
```bash
kubectl rollout restart deployment/firecrawl -n firecrawl
```

### Update
1. Edit `clusters/homelab/apps/firecrawl.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### API not responding
- **Symptom:** Health check fails
- **Cause:** Dependencies not ready (Redis, RabbitMQ, PostgreSQL)
- **Fix:** Check all container logs, ensure dependencies started first

### Playwright timeouts
- **Symptom:** Scraping JS-heavy pages times out
- **Cause:** Playwright service resource limits
- **Fix:** Increase memory/CPU limits for playwright container

### Database connection errors
- **Symptom:** API fails to start with DB errors
- **Cause:** PostgreSQL not initialized
- **Fix:** Check PostgreSQL container logs, verify PVC mounted

## Related

- External: https://github.com/mendableai/firecrawl
- Docs: https://docs.firecrawl.dev/

## Tags

#homelab #k8s #firecrawl #web-scraping #api #tailscale #ai
