# Service Specification: [Service Name]

> Spec Number: NNN
> Created: YYYY-MM-DD
> Status: Deployed | Planned | Deprecated
> Manifest: clusters/homelab/apps/[name].yaml

## Overview

[1-2 paragraph description of what this service provides and its purpose in the homelab cluster.]

## Service Requirements

### SR-1: [Primary Requirement]
- **Need:** [What capability is required]
- **Solution:** [How it's addressed in this deployment]
- **Verification:** `[kubectl command or URL to verify]`

### SR-2: [Secondary Requirement]
- **Need:** [What capability is required]
- **Solution:** [How it's addressed]
- **Verification:** `[kubectl command or URL to verify]`

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `[namespace]` |
| Image | `[image:tag]` |
| Replicas | [count] |
| Strategy | [Recreate/RollingUpdate] |

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | [XMi] | [XGi] |
| CPU | [Xm] | [Xm] |

### Health Probes

| Probe | Type | Port | Path | Initial Delay |
|-------|------|------|------|---------------|
| Readiness | [HTTP/TCP] | [port] | [path or N/A] | [Xs] |
| Liveness | [HTTP/TCP] | [port] | [path or N/A] | [Xs] |

## Networking

| Property | Value |
|----------|-------|
| Service Type | ClusterIP |
| Port | [port] |
| Ingress Class | [cloudflare-tunnel / tailscale / none] |
| Public URL | [URL or N/A] |
| Private URL | [URL or N/A] |

## Storage

| Property | Value |
|----------|-------|
| Storage Class | [synology-nfs / local-path / none] |
| Size | [XGi or N/A] |
| Mount Path | [path or N/A] |
| Access Mode | [ReadWriteOnce / ReadWriteMany / N/A] |

## Configuration

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| [VAR_NAME] | `[value]` | [description] |

### ConfigMaps

| ConfigMap | Keys | Purpose |
|-----------|------|---------|
| [name] | [keys] | [description] |

### Secrets

| Secret | Keys | Purpose |
|--------|------|---------|
| [name] | [keys] | [description] |

## Dependencies

### Requires
- [Service/component this depends on, or "None"]

### Required By
- [Services that depend on this, or "None"]

## Operations

### Status Check
```bash
kubectl get pods -n [namespace]
kubectl logs -n [namespace] -l app=[name] --tail=50
```

### Restart
```bash
kubectl rollout restart deployment/[name] -n [namespace]
```

### Update
1. Edit `clusters/homelab/apps/[name].yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### [Common Issue Name]
- **Symptom:** [What you observe]
- **Cause:** [Root cause]
- **Fix:** [Solution steps]

## Related

- Docs: [[docs/Apps/[name].md]]
- External: [Official documentation URL]

## Tags

#homelab #k8s #[category]
