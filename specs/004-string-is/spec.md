# Service Specification: string-is Encoding/Decoding Tool

> Spec Number: 004
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/string-is.yaml

## Overview

string-is is a web-based string manipulation and encoding/decoding utility. It provides tools for converting between various formats including Base64, URL encoding, JSON formatting, and more. Useful for developers working with encoded data.

## Service Requirements

### SR-1: String Manipulation
- **Need:** Tools for encoding/decoding strings in various formats
- **Solution:** Web UI with multiple conversion tools
- **Verification:** `curl -s https://string-is.marchi.app`

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `string-is` |
| Image | `daveperrett/string-is:latest` |
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
| Public URL | https://string-is.marchi.app |

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
kubectl get pods -n string-is
kubectl logs -n string-is -l app=string-is --tail=50
```

### Restart
```bash
kubectl rollout restart deployment/string-is -n string-is
```

### Update
1. Edit `clusters/homelab/apps/string-is.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### Page not loading
- **Symptom:** 502/503 error
- **Cause:** Pod not running or crashed
- **Fix:** Check pod logs, verify image exists

## Related

- Docs: [[docs/Apps/string-is.md]]
- External: https://github.com/daveperrett/string-is

## Tags

#homelab #k8s #tools #encoding #developer
