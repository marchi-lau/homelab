# Service Specification: www-delta-and-beta Website

> Spec Number: 014
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/www-delta-and-beta.yaml

## Overview

Static website for delta-and-beta.com. Built and deployed from GitHub Container Registry (ghcr.io) with Flux image automation for automatic updates when new versions are pushed.

## Service Requirements

### SR-1: Website Hosting
- **Need:** Host static website publicly
- **Solution:** Node.js container with static content
- **Verification:** `curl -s https://www.delta-and-beta.com`

### SR-2: Automatic Updates
- **Need:** Deploy new versions automatically on push
- **Solution:** Flux ImagePolicy and ImageUpdateAutomation
- **Verification:** Check ImagePolicy status in flux-system

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `www-delta-and-beta` |
| Image | `ghcr.io/delta-and-beta/www.delta-and-beta.com:<tag>` |
| Replicas | 1 |
| Strategy | RollingUpdate |

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
| Port | 3000 |
| Ingress Class | cloudflare-tunnel |
| Public URL | https://www.delta-and-beta.com |

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
| PORT | `3000` | Application port |

### Image Pull Secrets

| Secret | Purpose |
|--------|---------|
| ghcr-secret | Access to private ghcr.io repository |

### Flux Image Automation

| Resource | Location | Purpose |
|----------|----------|---------|
| ImageRepository | flux-system | Scans ghcr.io for new tags |
| ImagePolicy | flux-system | Selects latest commit tag |
| ImageUpdateAutomation | flux-system | Commits updated tags |

### Secrets

| Secret | Keys | Purpose |
|--------|------|---------|
| ghcr-secret | .dockerconfigjson | Pull images from ghcr.io |

## Dependencies

### Requires
- ghcr.io authentication (ghcr-secret)
- Flux image automation controllers
- Cloudflare Tunnel operator
- Flux GitOps

### Required By
- None

## Operations

### Status Check
```bash
kubectl get pods -n www-delta-and-beta
kubectl get imagepolicy -n flux-system www-delta-and-beta
flux get image policy www-delta-and-beta
```

### Force Image Update
```bash
flux reconcile image repository www-delta-and-beta
flux reconcile image update flux-system
```

### Restart
```bash
kubectl rollout restart deployment/www-delta-and-beta -n www-delta-and-beta
```

### Update
Image updates automatically via Flux ImagePolicy. Manual update:
1. Edit `clusters/homelab/apps/www-delta-and-beta.yaml`
2. Update image tag
3. Commit and push

## Troubleshooting

### Image pull failed
- **Symptom:** ErrImagePull or ImagePullBackOff
- **Cause:** ghcr-secret missing or expired
- **Fix:** Recreate ghcr-secret with fresh token

### Image not updating
- **Symptom:** New pushes not triggering deployment
- **Cause:** ImagePolicy not selecting new tags
- **Fix:** Check ImageRepository and ImagePolicy status

## Related

- Related manifests: www-delta-and-beta-image.yaml, www-delta-and-beta-automation.yaml
- External: https://github.com/delta-and-beta/www.delta-and-beta.com

## Tags

#homelab #k8s #website #flux #automation
