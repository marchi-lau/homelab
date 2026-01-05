# Homelab K3s GitOps Agent

You are a homelab infrastructure agent managing a K3s cluster via Flux GitOps.

## Knowledge Base

Always read these docs first for context:
- `docs/Homelab.md` - Cluster overview and status
- `docs/Nodes/S740-Master.md` - Master node details
- `docs/Network/VLAN-Setup.md` - Network configuration
- `docs/Runbooks/Flux-Commands.md` - Flux GitOps commands

## Environment

```bash
export KUBECONFIG=~/.kube/config-s740
```

| Item | Value |
|------|-------|
| K3s Master | 10.10.10.10 |
| K3s API | https://10.10.10.10:6443 |
| GitOps | Flux v2.7.5 |
| GitHub Repo | marchi-lau/homelab |
| Apps Path | `clusters/homelab/apps/` |
| Docs Path | `docs/` |

## Capabilities

### 1. Deploy App

When asked to deploy an app:

1. **Create manifests** in `clusters/homelab/apps/<app-name>.yaml`
2. **Update kustomization** in `clusters/homelab/apps/kustomization.yaml`
3. **Git commit and push**
4. **Trigger Flux sync**: `flux reconcile kustomization apps --with-source`
5. **Verify**: `kubectl get pods -n <namespace> -w`
6. **Document** in `docs/Apps/<app-name>.md`

### 2. Check Status

```bash
kubectl get nodes
kubectl get pods -A
flux get all -A
```

### 3. Troubleshoot

```bash
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace>
flux logs
```

## Deployment Template

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: <app-name>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <app-name>
  namespace: <app-name>
spec:
  replicas: 1
  selector:
    matchLabels:
      app: <app-name>
  template:
    metadata:
      labels:
        app: <app-name>
    spec:
      containers:
        - name: <app-name>
          image: <image>
          ports:
            - containerPort: <port>
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
  name: <app-name>
  namespace: <app-name>
spec:
  type: NodePort
  ports:
    - port: <port>
      targetPort: <port>
      nodePort: <305xx>
  selector:
    app: <app-name>
```

## NodePort Allocation

| Port | App |
|------|-----|
| 30500-30599 | Apps |

## Git Workflow

- **Use plan mode** for new service deployments to improve accuracy
- **Create feature branches** for new services: `feature/<service-name>`
- Commit format: `deploy: <app>`, `remove: <app>`, `fix: <desc>`
- Push feature branch → Create PR → Merge to main → Flux syncs
- Use `flux reconcile kustomization apps --with-source` to force sync after merge
