# Service Specification: AI Draw.io Diagramming

> Spec Number: 009
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/ai-drawio.yaml

## Overview

AI Draw.io is an AI-enhanced diagramming tool based on Draw.io/diagrams.net. It integrates with OpenAI's GPT-4 to assist with diagram creation and modification. Users can describe diagrams in natural language and have them generated automatically.

## Service Requirements

### SR-1: Diagramming Tool
- **Need:** Create and edit diagrams visually
- **Solution:** Draw.io-based editor
- **Verification:** `curl -s https://diagram.marchi.app`

### SR-2: AI Assistance
- **Need:** Natural language diagram generation
- **Solution:** OpenAI GPT-4o integration
- **Verification:** Create diagram using AI prompt

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `ai-drawio` |
| Image | `ghcr.io/dayuanjiang/next-ai-draw-io:latest` |
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
| Public URL | https://diagram.marchi.app |

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
| AI_PROVIDER | `openai` | AI backend provider |
| AI_MODEL | `gpt-4o` | Model for AI features |
| OPENAI_API_KEY | (from secret) | OpenAI authentication |

### Secrets

| Secret | Keys | Purpose |
|--------|------|---------|
| ai-drawio-config | OPENAI_API_KEY | OpenAI API authentication |

## Dependencies

### Requires
- OpenAI API access
- Cloudflare Tunnel operator
- Flux GitOps

### Required By
- Homepage dashboard (displays link)

## Operations

### Status Check
```bash
kubectl get pods -n ai-drawio
kubectl logs -n ai-drawio -l app=ai-drawio --tail=50
```

### Update API Key
```bash
kubectl edit secret ai-drawio-config -n ai-drawio
kubectl rollout restart deployment/ai-drawio -n ai-drawio
```

### Restart
```bash
kubectl rollout restart deployment/ai-drawio -n ai-drawio
```

### Update
1. Edit `clusters/homelab/apps/ai-drawio.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### AI features not working
- **Symptom:** AI generation fails or times out
- **Cause:** Invalid or missing OpenAI API key
- **Fix:** Verify OPENAI_API_KEY in secret is valid

## Related

- Docs: [[docs/Apps/ai-drawio.md]]
- External: https://github.com/dayuanjiang/next-ai-draw-io

## Tags

#homelab #k8s #tools #diagrams #ai #drawio
