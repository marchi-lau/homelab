# Flux Commands

Flux GitOps operations for the homelab cluster.

## Current Setup

| Property | Value |
|----------|-------|
| Flux Version | v2.7.5 |
| GitHub Repo | [marchi-lau/homelab](https://github.com/marchi-lau/homelab) |
| Path | clusters/homelab |
| Branch | main |
| Sync Interval | 10 minutes |

---

## Status & Monitoring

```bash
# All Flux resources
flux get all -A

# Kustomizations status
flux get kustomizations -A

# Git sources
flux get sources git -A

# Helm releases
flux get helmreleases -A

# Full health check
flux check
```

---

## Sync Operations

```bash
# Force sync apps (most common)
flux reconcile kustomization apps --with-source

# Sync flux-system
flux reconcile kustomization flux-system --with-source

# Sync git source only
flux reconcile source git flux-system
```

---

## Deploy an App

1. Create manifest in `clusters/homelab/apps/`:

```yaml
# clusters/homelab/apps/myapp.yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: myapp
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: myapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: myapp
          image: nginx:latest
          ports:
            - containerPort: 80
          resources:
            requests:
              memory: "64Mi"
              cpu: "50m"
            limits:
              memory: "128Mi"
              cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: myapp
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30500
  selector:
    app: myapp
```

2. Add to kustomization:

```yaml
# clusters/homelab/apps/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - myapp.yaml
```

3. Commit and push:

```bash
git add . && git commit -m "deploy: myapp" && git push
```

4. Sync:

```bash
flux reconcile kustomization apps --with-source
```

---

## Remove an App

1. Delete the manifest file
2. Remove from `kustomization.yaml`
3. Commit and push:

```bash
git add . && git commit -m "remove: myapp" && git push
```

4. Sync (prune enabled - resources auto-deleted):

```bash
flux reconcile kustomization apps --with-source
```

---

## Troubleshooting

```bash
# Flux logs (follow)
flux logs -f

# Error logs only
flux logs --level=error

# Specific kustomization logs
flux logs --kind=Kustomization --name=apps

# Check kustomization errors
flux get kustomization apps

# Describe for detailed error
kubectl describe kustomization apps -n flux-system
```

---

## Suspend & Resume

```bash
# Pause syncing (maintenance)
flux suspend kustomization apps

# Resume syncing
flux resume kustomization apps

# Check suspended status
flux get kustomizations
```

---

## Export Resources

```bash
# Export all sources
flux export source git --all > sources.yaml

# Export all kustomizations
flux export kustomization --all > kustomizations.yaml
```

---

## Bootstrap Reference

This cluster was bootstrapped with:

```bash
# Install Flux CLI
brew install fluxcd/tap/flux

# Switch to correct GitHub account
gh auth switch --user marchi-lau

# Bootstrap (already done)
export KUBECONFIG=~/.kube/config-s740
export GITHUB_TOKEN=$(gh auth token)

flux bootstrap github \
  --owner=marchi-lau \
  --repository=homelab \
  --path=clusters/homelab \
  --personal \
  --private=false
```

---

## Uninstall Flux

> **Warning:** Removes all Flux-managed resources!

```bash
flux uninstall
```

---

## Related

- [[Homelab|Homelab Dashboard]]
- [[Runbooks/Quick-Commands|Quick Commands]]
- [[Runbooks/Troubleshooting|Troubleshooting]]

## Tags

#homelab #flux #gitops #runbook
