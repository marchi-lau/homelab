# Service Specification: Excalidraw Whiteboard

> Spec Number: 010
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/excalidraw.yaml

## Overview

Excalidraw is a virtual collaborative whiteboard tool for creating hand-drawn like diagrams and sketches. It provides a simple, intuitive interface for quick visual brainstorming and documentation.

## Service Requirements

### SR-1: Whiteboard Tool
- **Need:** Quick sketch and diagramming tool
- **Solution:** Excalidraw web interface
- **Verification:** `curl -s https://excalidraw.marchi.app`

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `excalidraw` |
| Image | `excalidraw/excalidraw:latest` |
| Replicas | 1 |
| Strategy | RollingUpdate |

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 64Mi | 256Mi |
| CPU | 50m | 300m |

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
| Public URL | https://excalidraw.marchi.app |

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
kubectl get pods -n excalidraw
kubectl logs -n excalidraw -l app=excalidraw --tail=50
```

### Restart
```bash
kubectl rollout restart deployment/excalidraw -n excalidraw
```

### Update
1. Edit `clusters/homelab/apps/excalidraw.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### Page not loading
- **Symptom:** 502/503 error
- **Cause:** Pod not running
- **Fix:** Check pod status and logs

## Related

- External: https://excalidraw.com/

## Tags

#homelab #k8s #tools #whiteboard #diagrams
