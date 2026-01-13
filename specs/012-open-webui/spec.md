# Service Specification: Open WebUI AI Interface

> Spec Number: 012
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/open-webui.yaml

## Overview

Open WebUI is a self-hosted web interface for interacting with large language models (LLMs). It provides a ChatGPT-like experience for various AI models including OpenAI, Anthropic, Ollama, and others. Features include conversation history, model switching, and document upload.

## Service Requirements

### SR-1: LLM Chat Interface
- **Need:** Web UI for interacting with AI models
- **Solution:** Open WebUI with multi-model support
- **Verification:** `curl -s https://open-webui.marchi.app`

### SR-2: Persistent History
- **Need:** Conversation history across sessions
- **Solution:** 5Gi PVC on synology-nfs
- **Verification:** `kubectl get pvc -n open-webui`

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `open-webui` |
| Image | `ghcr.io/open-webui/open-webui:main` |
| Replicas | 1 |
| Strategy | Recreate |

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 512Mi | 2Gi |
| CPU | 200m | 2000m |

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
| Public URL | https://open-webui.marchi.app |

## Storage

| Property | Value |
|----------|-------|
| Storage Class | synology-nfs |
| Size | 5Gi |
| Mount Path | /app/backend/data |
| Access Mode | ReadWriteOnce |

## Configuration

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| WEBUI_AUTH | `True` | Enable authentication |
| WEBUI_URL | `https://open-webui.marchi.app` | Public URL |

### Secrets

| Secret | Keys | Purpose |
|--------|------|---------|
| N/A | N/A | API keys configured via UI |

## Dependencies

### Requires
- synology-nfs storage class
- Cloudflare Tunnel operator
- Flux GitOps
- External AI API (OpenAI/Anthropic/Ollama)

### Required By
- Homepage dashboard (displays link)

## Operations

### Status Check
```bash
kubectl get pods -n open-webui
kubectl logs -n open-webui -l app=open-webui --tail=50
```

### Restart
```bash
kubectl rollout restart deployment/open-webui -n open-webui
```

### Update
1. Edit `clusters/homelab/apps/open-webui.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### Cannot connect to AI model
- **Symptom:** Model responses fail
- **Cause:** API key invalid or model endpoint unreachable
- **Fix:** Check API keys in settings, verify network connectivity

### High memory usage
- **Symptom:** Pod OOM killed
- **Cause:** Large conversations or document uploads
- **Fix:** Increase memory limits, clear old conversations

## Related

- External: https://github.com/open-webui/open-webui

## Tags

#homelab #k8s #ai #llm #chat
