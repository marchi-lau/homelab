# Flux GitOps Setup

Complete guide for setting up Flux on the homelab K3s cluster.

## Prerequisites

| Requirement | Status |
|-------------|--------|
| K3s cluster running | ✅ Required |
| kubectl configured | ✅ Required |
| GitHub account | ✅ Required |
| GitHub CLI (gh) | ✅ Recommended |

---

## Installation Steps

### 1. Install Flux CLI

```bash
# macOS
brew install fluxcd/tap/flux

# Verify
flux --version
```

### 2. Pre-flight Check

```bash
export KUBECONFIG=~/.kube/config-s740
flux check --pre
```

Expected output:
```
► checking prerequisites
✔ Kubernetes 1.34.3+k3s1 >=1.32.0-0
✔ prerequisites checks passed
```

### 3. GitHub Authentication

```bash
# Check existing auth
gh auth status

# Switch to correct account if needed
gh auth switch --user marchi-lau

# Or login fresh
gh auth login
```

### 4. Bootstrap Flux

```bash
export KUBECONFIG=~/.kube/config-s740
export GITHUB_TOKEN=$(gh auth token)

flux bootstrap github \
  --owner=marchi-lau \
  --repository=homelab \
  --path=clusters/homelab \
  --personal \
  --private=false
```

This command:
- Creates the GitHub repository (if not exists)
- Installs Flux controllers in `flux-system` namespace
- Configures Flux to sync from the repository
- Sets up deploy keys for secure access

### 5. Verify Installation

```bash
# Check all components
flux check

# View Flux resources
flux get all -A

# Check pods
kubectl get pods -n flux-system
```

---

## Post-Bootstrap Configuration

### Create Apps Kustomization

Flux bootstrap only creates the base `flux-system` kustomization. To deploy apps, create an additional kustomization:

1. Create `clusters/homelab/flux-system/apps-kustomization.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps
  namespace: flux-system
spec:
  interval: 10m
  path: ./clusters/homelab/apps
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
```

2. Add to `clusters/homelab/flux-system/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- gotk-components.yaml
- gotk-sync.yaml
- apps-kustomization.yaml
```

3. Create apps directory structure:

```bash
mkdir -p clusters/homelab/apps
```

4. Create `clusters/homelab/apps/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources: []
```

5. Commit and push:

```bash
git add . && git commit -m "feat: add apps kustomization" && git push
```

6. Sync:

```bash
flux reconcile kustomization flux-system --with-source
```

---

## Repository Structure

After setup, your repository should look like:

```
homelab/
├── clusters/
│   └── homelab/
│       ├── apps/
│       │   └── kustomization.yaml    # List apps here
│       └── flux-system/
│           ├── gotk-components.yaml  # Flux CRDs & controllers
│           ├── gotk-sync.yaml        # GitRepository & Kustomization
│           ├── apps-kustomization.yaml
│           └── kustomization.yaml
├── CLAUDE.md
└── README.md
```

---

## Key Concepts

### Kustomizations

Two types of kustomizations exist:

1. **Kustomize Kustomization** (`kustomize.config.k8s.io/v1beta1`)
   - Standard Kubernetes kustomization
   - Lists resources to include
   - Used in `apps/kustomization.yaml`

2. **Flux Kustomization** (`kustomize.toolkit.fluxcd.io/v1`)
   - Flux CRD for reconciliation
   - Points to a path in a GitRepository
   - Controls sync interval and pruning
   - Used in `apps-kustomization.yaml`

### Pruning

With `prune: true`, Flux automatically deletes resources that are removed from Git. This enables true GitOps - the repo is the source of truth.

### Sync Interval

Default is 10 minutes. For faster syncing during development:

```yaml
spec:
  interval: 1m
```

---

## Troubleshooting

### Bootstrap Fails

```bash
# Check GitHub token permissions
gh auth status

# Ensure repo scope is available
# Token needs: repo, admin:public_key
```

### Kustomization Not Ready

```bash
# Check detailed status
flux get kustomization apps
kubectl describe kustomization apps -n flux-system

# Check logs
flux logs --kind=Kustomization --name=apps
```

### Resources Not Syncing

```bash
# Force sync
flux reconcile kustomization apps --with-source

# Check GitRepository
flux get sources git
```

---

## Related

- [[Runbooks/Flux-Commands|Flux Commands]]
- [[Homelab|Homelab Dashboard]]
- [[Nodes/S740-Master|S740 Master Node]]

## Tags

#homelab #flux #gitops #setup #implementation
