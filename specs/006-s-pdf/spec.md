# Service Specification: Stirling PDF Processor

> Spec Number: 006
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/s-pdf.yaml

## Overview

Stirling PDF is a self-hosted PDF manipulation tool. It provides a web interface for merging, splitting, converting, and modifying PDF documents. All processing happens locally without uploading files to external services.

## Service Requirements

### SR-1: PDF Processing
- **Need:** Local PDF manipulation without external services
- **Solution:** Stirling PDF with comprehensive toolset
- **Verification:** `curl -s https://s-pdf.marchi.app`

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `s-pdf` |
| Image | `frooodle/s-pdf:latest` |
| Replicas | 1 |
| Strategy | RollingUpdate |

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 512Mi | 1Gi |
| CPU | 100m | 1000m |

### Health Probes

| Probe | Type | Port | Path | Initial Delay |
|-------|------|------|------|---------------|
| N/A | N/A | N/A | N/A | N/A |

## Networking

| Property | Value |
|----------|-------|
| Service Type | ClusterIP |
| Port | 8080 |
| Ingress Class | cloudflare-tunnel |
| Public URL | https://s-pdf.marchi.app |

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
| DOCKER_ENABLE_SECURITY | `false` | Disable authentication |
| INSTALL_BOOK_AND_ADVANCED_HTML_OPS | `false` | Skip optional dependencies |
| SYSTEM_DEFAULTLOCALE | `en_US` | System locale |

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
kubectl get pods -n s-pdf
kubectl logs -n s-pdf -l app=s-pdf --tail=50
```

### Restart
```bash
kubectl rollout restart deployment/s-pdf -n s-pdf
```

### Update
1. Edit `clusters/homelab/apps/s-pdf.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### High memory usage during conversion
- **Symptom:** Pod OOM killed during large PDF processing
- **Cause:** Large PDF files require more memory
- **Fix:** Increase memory limits or process smaller files

## Related

- Docs: [[docs/Apps/s-pdf.md]]
- External: https://github.com/Stirling-Tools/Stirling-PDF

## Tags

#homelab #k8s #tools #pdf #document
