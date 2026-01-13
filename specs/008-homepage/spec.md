# Service Specification: Homepage Dashboard

> Spec Number: 008
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/homepage.yaml

## Overview

Homepage is a highly customizable application dashboard. It serves as the central landing page for the homelab, providing quick access to all services, weather widgets, and bookmarks. Configuration is managed via ConfigMap with custom CSS theming.

## Service Requirements

### SR-1: Service Dashboard
- **Need:** Central hub for accessing homelab services
- **Solution:** Homepage with categorized service links
- **Verification:** `curl -s https://homepage.marchi.app`

### SR-2: Custom Theming
- **Need:** Branded appearance matching homelab style
- **Solution:** Custom CSS via ConfigMap
- **Verification:** Visual inspection of dashboard

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `homepage` |
| Image | `ghcr.io/gethomepage/homepage:latest` |
| Replicas | 1 |
| Strategy | RollingUpdate |

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 64Mi | 128Mi |
| CPU | 25m | 200m |

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
| Public URL | https://homepage.marchi.app |

## Storage

| Property | Value |
|----------|-------|
| Storage Class | none (ConfigMap + emptyDir) |
| Size | N/A |
| Mount Path | /app/config |
| Access Mode | N/A |

## Configuration

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| HOMEPAGE_ALLOWED_HOSTS | `homepage.marchi.app` | Host header validation |

### ConfigMaps

| ConfigMap | Keys | Purpose |
|-----------|------|---------|
| homepage-config | settings.yaml, services.yaml, bookmarks.yaml, widgets.yaml, kubernetes.yaml, docker.yaml, custom.css | All dashboard configuration |

### Init Containers

| Container | Image | Purpose |
|-----------|-------|---------|
| copy-config | busybox:1.36 | Copy ConfigMap to writable emptyDir |

### Secrets

| Secret | Keys | Purpose |
|--------|------|---------|
| N/A | N/A | No secrets required |

## Dependencies

### Requires
- Cloudflare Tunnel operator
- Flux GitOps

### Required By
- None (entry point for users)

## Operations

### Status Check
```bash
kubectl get pods -n homepage
kubectl logs -n homepage -l app=homepage --tail=50
```

### Update Configuration
1. Edit `homepage-config` ConfigMap in `clusters/homelab/apps/homepage.yaml`
2. Commit and push
3. Restart pod: `kubectl rollout restart deployment/homepage -n homepage`

### Restart
```bash
kubectl rollout restart deployment/homepage -n homepage
```

### Update
1. Edit `clusters/homelab/apps/homepage.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### Configuration not updating
- **Symptom:** Changes to ConfigMap not reflected
- **Cause:** ConfigMap changes require pod restart
- **Fix:** `kubectl rollout restart deployment/homepage -n homepage`

## Related

- Docs: [[docs/Apps/homepage.md]]
- External: https://gethomepage.dev/

## Tags

#homelab #k8s #dashboard #homepage
