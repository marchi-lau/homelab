# Service Specification: IT-Tools Web Utilities

> Spec Number: 005
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/it-tools.yaml

## Overview

IT-Tools is a comprehensive collection of handy online tools for developers and IT professionals. Includes converters, generators, formatters, and various utilities like hash generators, UUID creators, and more. All tools run client-side for privacy.

## Service Requirements

### SR-1: Developer Utilities
- **Need:** Quick access to common developer tools
- **Solution:** 100+ tools in single web interface
- **Verification:** `curl -s https://it-tools.marchi.app`

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `it-tools` |
| Image | `corentinth/it-tools:latest` |
| Replicas | 1 |
| Strategy | RollingUpdate |

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 64Mi | 128Mi |
| CPU | 50m | 200m |

### Health Probes

| Probe | Type | Port | Path | Initial Delay |
|-------|------|------|------|---------------|
| N/A | N/A | N/A | N/A | N/A |

## Networking

| Property | Value |
|----------|-------|
| Service Type | ClusterIP |
| Port | 80 |
| Ingress Class | cloudflare-tunnel |
| Public URL | https://it-tools.marchi.app |

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
| N/A | N/A | Default configuration |

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

## Operations

### Status Check
```bash
kubectl get pods -n it-tools
kubectl logs -n it-tools -l app=it-tools --tail=50
```

### Restart
```bash
kubectl rollout restart deployment/it-tools -n it-tools
```

### Update
1. Edit `clusters/homelab/apps/it-tools.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### Page not loading
- **Symptom:** 502/503 error
- **Cause:** Pod not running
- **Fix:** Check pod status and logs

## Related

- Docs: [[docs/Apps/it-tools.md]]
- External: https://github.com/CorentinTh/it-tools

## Tags

#homelab #k8s #tools #developer #utilities
