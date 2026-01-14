# Service Specification: AI Workstation Development Environment

> Spec Number: 018
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/ai-workstation.yaml

## Overview

AI Workstation is a remote development environment running Ubuntu 24.04 with pre-installed AI coding tools. Provides SSH access for development with Claude Code, Aider, and other AI-assisted coding tools. Data persists on NFS storage.

## Service Requirements

### SR-1: Remote Development Environment
- **Need:** Accessible dev environment with AI tools
- **Solution:** Ubuntu container with SSH server
- **Verification:** `ssh dev@ai-workstation.<tailnet>.ts.net`

### SR-2: AI Coding Tools
- **Need:** Pre-installed AI coding assistants
- **Solution:** Claude Code, Aider, GitHub CLI
- **Verification:** Run `ai-status` after SSH login

### SR-3: Persistent Workspace
- **Need:** Code and config survives restarts
- **Solution:** 20Gi PVC on synology-nfs
- **Verification:** `kubectl get pvc -n ai-workstation`

### SR-4: API Keys Access
- **Need:** AI tools need API credentials
- **Solution:** Secrets mounted as environment variables
- **Verification:** Check `ai-status` for configured keys

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `ai-workstation` |
| Image | `ubuntu:24.04` |
| Replicas | 1 |
| Strategy | Recreate |

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 512Mi | 8Gi |
| CPU | 200m | 4000m |

### Health Probes

| Probe | Type | Port | Path | Initial Delay |
|-------|------|------|------|---------------|
| N/A | N/A | N/A | N/A | N/A |

## Networking

| Property | Value |
|----------|-------|
| Service Type | ClusterIP |
| Ports | 22 (SSH), 3000 (HTTP) |
| Ingress Class | N/A (Tailscale Service) |
| Public URL | N/A |
| Private URL | ai-workstation.<tailnet>.ts.net (SSH) |

### Service Annotations

| Annotation | Value | Purpose |
|------------|-------|---------|
| tailscale.com/expose | true | Expose via Tailscale |
| tailscale.com/hostname | ai-workstation | Tailscale hostname |
| tailscale.com/tags | tag:kubernetes | Tailscale ACL tags |

## Storage

| Property | Value |
|----------|-------|
| Storage Class | synology-nfs |
| Size | 20Gi |
| Mount Path | /data |
| Access Mode | ReadWriteOnce |

### Persistent Directories

| Path | Purpose |
|------|---------|
| /data/workspace | Code repositories |
| /data/.claude | Claude Code config |
| /data/.aider | Aider config |
| /data/ssh | SSH host keys |

## Configuration

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| ANTHROPIC_API_KEY | (from secret) | Claude API access |
| OPENAI_API_KEY | (from secret) | OpenAI API access |
| GEMINI_API_KEY | (from secret) | Google AI access |

### ConfigMaps

| ConfigMap | Keys | Purpose |
|-----------|------|---------|
| ai-workstation-setup | setup.sh | Installation and configuration script |

### Init Containers

| Container | Image | Purpose |
|-----------|-------|---------|
| fix-permissions | busybox:1.36 | Fix NFS permissions (777, 1001:1001) |

### Security Context

| Property | Value | Purpose |
|----------|-------|---------|
| fsGroup | 1001 | Group ownership for volumes |

### Secrets

| Secret | Keys | Purpose |
|--------|------|---------|
| ai-workstation-secrets | anthropic-api-key, openai-api-key, gemini-api-key | AI API credentials |

## Installed Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Claude Code | latest | AI coding assistant |
| Aider | latest | Multi-LLM coding tool |
| Node.js | 22.x | JavaScript runtime |
| Python | 3.x | Python runtime |
| GitHub CLI | latest | GitHub operations |
| tmux | system | Terminal multiplexer |

### Shell Aliases

| Alias | Command | Purpose |
|-------|---------|---------|
| c | `claude --dangerously-skip-permissions` | Quick Claude Code |
| t | tmux session (dir-named) | Create/attach session |
| w | tmux with claude window | Session with claude window |
| d | `tmux detach` | Detach from session |
| gs | `git status` | Git status |
| gp | `git pull` | Git pull |

## Dependencies

### Requires
- synology-nfs storage class
- Tailscale operator
- AI API keys (Anthropic, OpenAI, etc.)
- Flux GitOps

### Required By
- None (end-user tool)

## Operations

### Status Check
```bash
kubectl get pods -n ai-workstation
kubectl logs -n ai-workstation -l app=ai-workstation --tail=100
```

### Connect via SSH
```bash
ssh dev@ai-workstation.<tailnet>.ts.net
# Password: dev (change on first login)
```

### Add SSH Key
```bash
# On local machine
ssh-copy-id dev@ai-workstation.<tailnet>.ts.net
# Then on workstation
save-ssh-keys  # Persist to NFS
```

### Update API Keys
```bash
kubectl edit secret ai-workstation-secrets -n ai-workstation
kubectl rollout restart deployment/ai-workstation -n ai-workstation
```

### Restart
```bash
kubectl rollout restart deployment/ai-workstation -n ai-workstation
```

### Update
1. Edit `clusters/homelab/apps/ai-workstation.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### SSH connection refused
- **Symptom:** Cannot SSH to workstation
- **Cause:** SSHD not running or Tailscale issue
- **Fix:** Check pod logs, verify Tailscale service expose

### API keys not working
- **Symptom:** AI tools fail with auth errors
- **Cause:** Secret not configured or invalid keys
- **Fix:** Verify secret exists with correct keys

### Workspace not persisted
- **Symptom:** Files disappear after restart
- **Cause:** Not using /data directories
- **Fix:** Store code in /data/workspace

## Related

- External: https://github.com/anthropics/claude-code

## Implementation Notes (2026-01-14)

### Files Modified
| File | Changes |
|------|---------|
| `clusters/homelab/apps/ai-workstation.yaml` | Added tmux helper aliases (t, w, d, b) and functions |

### Features Implemented
- [x] `b` alias - Edit .bashrc with nano
- [x] `d` alias - Detach from tmux session
- [x] `t()` function - Create/attach tmux session named after current directory
- [x] `w()` function - Create tmux session with dedicated claude window
- [x] Updated ai-status to show quick command reference

### Related Commits
- `4f9d946` feat(ai-workstation): add tmux helper aliases and functions
- `3b3ac90` feat: add claude alias 'c' to ai-workstation
- `acbd873` fix: ai-workstation - persistent SSH keys, tmux TERM fix, bashrc setup

## Tags

#homelab #k8s #development #ai #coding #ssh #tailscale
