# Service Specification: Miniflux RSS Reader

> Spec Number: 011
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/miniflux.yaml

## Overview

Miniflux is a minimalist RSS/Atom feed reader. It provides a clean, fast interface for reading feeds with built-in full-text content retrieval. Includes PostgreSQL database for feed storage.

## Service Requirements

### SR-1: RSS Feed Reading
- **Need:** Aggregate and read RSS/Atom feeds
- **Solution:** Miniflux with PostgreSQL backend
- **Verification:** `curl -s https://miniflux.marchi.app`

### SR-2: Persistent Storage
- **Need:** Feed data persists across restarts
- **Solution:** PostgreSQL with 2Gi PVC on synology-nfs
- **Verification:** `kubectl get pvc -n miniflux`

## Deployment Configuration

### Miniflux

| Property | Value |
|----------|-------|
| Namespace | `miniflux` |
| Image | `miniflux/miniflux:latest` |
| Replicas | 1 |
| Strategy | RollingUpdate |

### PostgreSQL

| Property | Value |
|----------|-------|
| Image | `postgres:15-alpine` |
| Replicas | 1 |
| Strategy | Recreate |

### Resources (Miniflux)

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 64Mi | 256Mi |
| CPU | 50m | 300m |

### Resources (PostgreSQL)

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 128Mi | 256Mi |
| CPU | 50m | 200m |

### Health Probes

| Probe | Type | Port | Path | Initial Delay |
|-------|------|------|------|---------------|
| N/A | N/A | N/A | N/A | N/A |

## Networking

| Property | Value |
|----------|-------|
| Service Type | ClusterIP |
| Miniflux Port | 8080 |
| PostgreSQL Port | 5432 (internal) |
| Ingress Class | cloudflare-tunnel |
| Public URL | https://miniflux.marchi.app |

## Storage

| Property | Value |
|----------|-------|
| Storage Class | synology-nfs |
| Size | 2Gi |
| Mount Path | /var/lib/postgresql/data |
| Access Mode | ReadWriteOnce |

## Configuration

### Environment Variables (Miniflux)

| Variable | Value | Purpose |
|----------|-------|---------|
| DATABASE_URL | `postgres://miniflux:miniflux-secret@miniflux-postgres:5432/miniflux?sslmode=disable` | PostgreSQL connection |
| RUN_MIGRATIONS | `1` | Auto-run migrations |
| CREATE_ADMIN | `1` | Create admin on first run |
| ADMIN_USERNAME | `admin` | Default admin user |
| ADMIN_PASSWORD | `changeme123` | Default password (change!) |
| BASE_URL | `https://miniflux.marchi.app` | Public URL |

### Environment Variables (PostgreSQL)

| Variable | Value | Purpose |
|----------|-------|---------|
| POSTGRES_USER | `miniflux` | Database user |
| POSTGRES_PASSWORD | `miniflux-secret` | Database password |
| POSTGRES_DB | `miniflux` | Database name |

### Init Containers

| Container | Image | Purpose |
|-----------|-------|---------|
| wait-for-postgres | busybox:1.36 | Wait for PostgreSQL to be ready |

### Secrets

| Secret | Keys | Purpose |
|--------|------|---------|
| N/A | N/A | Credentials in env vars (consider secrets) |

## Dependencies

### Requires
- synology-nfs storage class
- Cloudflare Tunnel operator
- Flux GitOps

### Required By
- Homepage dashboard (displays link)
- RSSHub (can provide feeds)

## Operations

### Status Check
```bash
kubectl get pods -n miniflux
kubectl logs -n miniflux -l app=miniflux --tail=50
kubectl logs -n miniflux -l app=miniflux-postgres --tail=50
```

### Restart
```bash
kubectl rollout restart deployment/miniflux -n miniflux
```

### Update
1. Edit `clusters/homelab/apps/miniflux.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### Cannot connect to database
- **Symptom:** Miniflux fails to start, connection refused
- **Cause:** PostgreSQL not ready or wrong credentials
- **Fix:** Check PostgreSQL pod status, verify DATABASE_URL

### Login fails
- **Symptom:** Cannot login with admin credentials
- **Cause:** Password was changed or CREATE_ADMIN already ran
- **Fix:** Reset password via miniflux CLI in pod

## Related

- External: https://miniflux.app/

## Tags

#homelab #k8s #rss #reader #feeds
