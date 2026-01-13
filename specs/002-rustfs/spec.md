# Service Specification: RustFS S3-Compatible Storage

> Spec Number: 002
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/rustfs.yaml

## Overview

RustFS is a MinIO-compatible S3 object storage server written in Rust. It provides an S3-compatible API for storing and retrieving objects, along with a web console for management. Used for hosting static assets, backups, and file storage across homelab services.

## Service Requirements

### SR-1: S3-Compatible API
- **Need:** Standard S3 API for object storage
- **Solution:** RustFS API endpoint on port 9000
- **Verification:** `aws s3 ls --endpoint-url=https://s3.marchi.app`

### SR-2: Web Management Console
- **Need:** GUI for bucket/object management
- **Solution:** RustFS console on port 9001
- **Verification:** `curl -s https://s3-console.marchi.app`

### SR-3: Persistent Storage
- **Need:** Data survives pod restarts
- **Solution:** 10Gi PVC on synology-nfs with fsGroup 10001
- **Verification:** `kubectl get pvc -n rustfs`

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `rustfs` |
| Image | `rustfs/rustfs:latest` |
| Replicas | 1 |
| Strategy | Recreate |

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 256Mi | 1Gi |
| CPU | 100m | 500m |

### Health Probes

| Probe | Type | Port | Path | Initial Delay |
|-------|------|------|------|---------------|
| Readiness | TCP | 9000 | N/A | 5s |
| Liveness | TCP | 9000 | N/A | 15s |

## Networking

| Property | Value |
|----------|-------|
| Service Type | ClusterIP |
| Ports | 9000 (API), 9001 (Console) |
| Ingress Class | cloudflare-tunnel |
| Public URL (API) | https://s3.marchi.app |
| Public URL (Console) | https://s3-console.marchi.app |

## Storage

| Property | Value |
|----------|-------|
| Storage Class | synology-nfs |
| Size | 10Gi |
| Mount Path | /data |
| Access Mode | ReadWriteOnce |

## Configuration

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| N/A | N/A | Default configuration used |

### Security Context

| Property | Value | Purpose |
|----------|-------|---------|
| fsGroup | 10001 | Group ownership for NFS volumes |

### Secrets

| Secret | Keys | Purpose |
|--------|------|---------|
| N/A | N/A | Default credentials (change on first login) |

## Dependencies

### Requires
- synology-nfs storage class
- Cloudflare Tunnel operator
- Flux GitOps

### Required By
- Homepage dashboard (displays RustFS links)
- Any service needing S3 storage

## Operations

### Status Check
```bash
kubectl get pods -n rustfs
kubectl logs -n rustfs -l app=rustfs --tail=50
```

### Restart
```bash
kubectl rollout restart deployment/rustfs -n rustfs
```

### Update
1. Edit `clusters/homelab/apps/rustfs.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### API returns 503
- **Symptom:** S3 operations fail with 503
- **Cause:** RustFS not yet ready, probe failing
- **Fix:** Wait for readiness probe, check logs for errors

### Permission denied on data directory
- **Symptom:** Pod fails to start, permission errors in logs
- **Cause:** fsGroup not matching NFS permissions
- **Fix:** Verify fsGroup: 10001 is set, check Synology NFS settings

## Related

- Docs: [[docs/Apps/rustfs.md]]
- External: https://github.com/rustfs/rustfs

## Tags

#homelab #k8s #storage #s3 #rustfs
