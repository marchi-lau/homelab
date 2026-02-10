# Service Specification: ChartDB

> Spec Number: 022
> Created: 2026-02-10
> Status: Planned
> Manifest: clusters/homelab/apps/chartdb.yaml

## Overview

ChartDB is a web-based database diagramming editor for visualizing and designing database schemas. It supports importing schemas from PostgreSQL, MySQL, SQL Server, MariaDB, SQLite, and more via a single query, and can export DDL scripts for migration between database dialects.

## Service Requirements

### SR-1: Database Schema Visualization
- **Need:** Web UI to visualize and edit database schemas
- **Solution:** Deploy ChartDB container with Cloudflare Tunnel ingress
- **Verification:** `curl -s -o /dev/null -w "%{http_code}" https://chartdb.marchi.app`

### SR-2: Privacy
- **Need:** Disable telemetry/analytics
- **Solution:** Set `DISABLE_ANALYTICS=true` environment variable
- **Verification:** Check env in pod: `kubectl exec -n chartdb deploy/chartdb -- env | grep ANALYTICS`

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `chartdb` |
| Image | `ghcr.io/chartdb/chartdb:latest` |
| Replicas | 1 |
| Strategy | RollingUpdate |

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 64Mi | 128Mi |
| CPU | 50m | 200m |

## Networking

| Property | Value |
|----------|-------|
| Service Type | ClusterIP |
| Port | 80 |
| Ingress Class | cloudflare-tunnel |
| Public URL | https://chartdb.marchi.app |
| Private URL | N/A |

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
| DISABLE_ANALYTICS | `true` | Disable telemetry |

### ConfigMaps

None.

### Secrets

None.

## Dependencies

### Requires
- None

### Required By
- None

## Operations

### Status Check
```bash
kubectl get pods -n chartdb
kubectl logs -n chartdb -l app=chartdb --tail=50
```

### Restart
```bash
kubectl rollout restart deployment/chartdb -n chartdb
```

### Update
1. Edit `clusters/homelab/apps/chartdb.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Related

- Docs: [[docs/Apps/chartdb.md]]
- External: https://github.com/chartdb/chartdb

## Tags

#homelab #k8s #database #diagramming
