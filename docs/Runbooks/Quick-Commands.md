# Quick Commands

Copy-paste reference for common homelab operations.

## Setup (One-time)

```bash
# Add to shell config
echo 'export KUBECONFIG=~/.kube/config-s740' >> ~/.zshrc
source ~/.zshrc
```

---

## Daily Use

### Cluster Status

```bash
# Nodes
kubectl get nodes

# All pods
kubectl get pods -A

# Problem pods only
kubectl get pods -A | grep -v Running | grep -v Completed

# Recent events
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# Full status
flux get all -A && kubectl get pods -A
```

### Node Access

```bash
# SSH to master
ssh ubuntu@10.10.10.10

# Quick health check
ssh ubuntu@10.10.10.10 "uptime && free -h && df -h /"
```

---

## Flux GitOps

### Status

```bash
# All Flux resources
flux get all -A

# Kustomizations
flux get kustomizations -A

# Health check
flux check
```

### Sync

```bash
# Sync apps (most common)
flux reconcile kustomization apps --with-source

# Sync everything
flux reconcile kustomization flux-system --with-source

# View logs
flux logs -f
```

### Deploy Workflow

```bash
# 1. Add manifest to clusters/homelab/apps/
# 2. Update apps/kustomization.yaml
# 3. Commit and push
git add . && git commit -m "deploy: app-name" && git push

# 4. Sync
flux reconcile kustomization apps --with-source
```

### Remove App

```bash
# 1. Delete manifest, update kustomization.yaml
# 2. Commit and push
git add . && git commit -m "remove: app-name" && git push

# 3. Sync (prune auto-deletes)
flux reconcile kustomization apps --with-source
```

---

## K3s Management

```bash
# Status (on node)
sudo systemctl status k3s

# Logs (on node)
sudo journalctl -u k3s -f

# Restart (on node)
sudo systemctl restart k3s

# Update K3s (on node)
curl -sfL https://get.k3s.io | sudo sh -
```

---

## Pod Operations

```bash
# Logs
kubectl logs -n <namespace> <pod>

# Follow logs
kubectl logs -n <namespace> <pod> -f

# Exec into pod
kubectl exec -it -n <namespace> <pod> -- /bin/sh

# Describe
kubectl describe pod -n <namespace> <pod>

# Delete pod (will restart if managed)
kubectl delete pod -n <namespace> <pod>
```

---

## Deployments

```bash
# Restart deployment
kubectl rollout restart deployment/<name> -n <namespace>

# Scale
kubectl scale deployment/<name> -n <namespace> --replicas=2

# Check rollout status
kubectl rollout status deployment/<name> -n <namespace>
```

---

## Storage

```bash
# PVCs
kubectl get pvc -A

# PVs
kubectl get pv

# Storage classes
kubectl get storageclass
```

---

## Network

```bash
# Services
kubectl get svc -A

# Ingress
kubectl get ingress -A

# Test from Mac
ping 10.10.10.10
curl http://10.10.10.10:<nodeport>
```

---

## Cleanup

```bash
# Delete completed pods
kubectl delete pods --field-selector=status.phase=Succeeded -A

# Delete failed pods
kubectl delete pods --field-selector=status.phase=Failed -A

# Node cleanup (on node)
ssh ubuntu@10.10.10.10 "sudo apt autoremove -y && sudo apt clean"

# Container image cleanup (on node)
ssh ubuntu@10.10.10.10 "sudo k3s crictl rmi --prune"
```

---

## Backup

```bash
# Kubeconfig backup
cp ~/.kube/config-s740 ~/backups/config-s740-$(date +%Y%m%d)

# K3s state backup (on node)
sudo tar -czf /tmp/k3s-backup.tar.gz /var/lib/rancher/k3s/server
```

---

## IP Reference

| Device | IP |
|--------|-----|
| S740 Master | 10.10.10.10 |
| Gateway | 10.10.10.1 |
| Synology (future) | 10.10.10.50 |
| Synology VM (future) | 10.10.10.20 |

## Tags

#homelab #commands #reference
