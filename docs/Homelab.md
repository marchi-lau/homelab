# Homelab

K3s Kubernetes cluster on Fujitsu S740 + Synology NAS with Flux GitOps.

## Quick Links

- [[Nodes/S740-Master|S740 Master Node]] - Implementation guide
- [[Network/VLAN-Setup|VLAN Configuration]]
- [[Runbooks/Quick-Commands|Quick Commands]]
- [[Runbooks/Flux-Commands|Flux GitOps Commands]]

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   Homelab Network (VLAN 10)                     │
│                       10.10.10.0/24                             │
│                                                                 │
│   ┌─────────────────┐           ┌─────────────────────────────┐ │
│   │  S740 Master    │           │     Synology DS1821+        │ │
│   │  10.10.10.10    │           │     (Future)                │ │
│   │                 │           │                             │ │
│   │  ✅ K3s Server  │           │  ⏳ VM Worker: 10.10.10.20  │ │
│   │  ✅ Ubuntu 24.04│           │  ⏳ NFS Storage: 10.10.10.50│ │
│   │  ✅ Flux GitOps │           │     64GB RAM                │ │
│   │  ✅ 4GB RAM     │           │                             │ │
│   └─────────────────┘           └─────────────────────────────┘ │
│            │                                                    │
│            ▼                                                    │
│   ┌─────────────────┐                                           │
│   │  GitHub Repo    │                                           │
│   │  marchi-lau/    │◄──── Flux syncs every 10m                 │
│   │  homelab        │                                           │
│   └─────────────────┘                                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Current Status

| Component | Status | Details |
|-----------|--------|---------|
| **S740 Master** | ✅ Running | K3s v1.34.3, 10.10.10.10 |
| **Flux GitOps** | ✅ Running | v2.7.5, syncing from GitHub |
| **GitHub Repo** | ✅ Active | [marchi-lau/homelab](https://github.com/marchi-lau/homelab) |
| Synology Worker | ⏳ Planned | VM on DS1821+ |
| NFS Storage | ⏳ Planned | Synology share |
| n8n | ⏳ Planned | Workflow automation |

---

## GitOps Workflow

Deploy apps by pushing to the GitHub repository:

```bash
# 1. Add manifest to clusters/homelab/apps/
# 2. Update clusters/homelab/apps/kustomization.yaml
# 3. Commit and push
git add . && git commit -m "deploy: app-name" && git push

# 4. Force sync (or wait ~10 min)
flux reconcile kustomization apps --with-source

# 5. Verify
kubectl get pods -n app-name
```

---

## Quick Access

### From Mac (on Homelab WiFi)

```bash
# Set kubeconfig
export KUBECONFIG=~/.kube/config-s740

# Check cluster
kubectl get nodes

# Check Flux status
flux get all -A

# SSH to node
ssh ubuntu@10.10.10.10
```

### Cluster Info

| Property | Value |
|----------|-------|
| K3s Version | v1.34.3+k3s1 |
| Flux Version | v2.7.5 |
| API Server | https://10.10.10.10:6443 |
| Kubeconfig | ~/.kube/config-s740 |
| GitOps Repo | github.com/marchi-lau/homelab |
| GitOps Path | clusters/homelab |

---

## Flux Components

| Controller | Status | Purpose |
|------------|--------|---------|
| source-controller | ✅ Running | Fetches Git/Helm sources |
| kustomize-controller | ✅ Running | Applies Kustomizations |
| helm-controller | ✅ Running | Manages HelmReleases |
| notification-controller | ✅ Running | Handles alerts/webhooks |

---

## Implementation Progress

- [x] UniFi VLAN "Homelab" (10.10.10.0/24)
- [x] S740 Ubuntu 24.04.1 LTS installation
- [x] Static IP configuration (10.10.10.10)
- [x] SSH key authentication
- [x] SSH agent sudo (secure)
- [x] K3s master installation
- [x] Kubeconfig on Mac
- [x] Flux CLI installed (v2.7.5)
- [x] GitHub repository created
- [x] Flux bootstrapped to cluster
- [x] Apps Kustomization configured
- [ ] Synology VM worker node
- [ ] NFS StorageClass
- [ ] n8n deployment

---

## Repository Structure

```
homelab/
├── clusters/
│   └── homelab/
│       ├── apps/                    # Application manifests
│       │   └── kustomization.yaml   # Apps to deploy
│       └── flux-system/             # Flux components
│           ├── gotk-components.yaml
│           ├── gotk-sync.yaml
│           ├── apps-kustomization.yaml
│           └── kustomization.yaml
├── CLAUDE.md
└── README.md
```

---

## Hardware Inventory

| Device | Model | RAM | Role | Status |
|--------|-------|-----|------|--------|
| S740 | Fujitsu S740 | 4GB | K3s Master | ✅ Running |
| Synology | DS1821+ | 64GB | Worker + Storage | ⏳ Planned |

---

## Network Info

| Item | Value |
|------|-------|
| VLAN Name | Homelab |
| VLAN ID | 10 |
| Subnet | 10.10.10.0/24 |
| Gateway | 10.10.10.1 |
| WiFi | "Homelab" (WPA3) |

---

## NodePort Allocation

| Port | App | Status |
|------|-----|--------|
| 30500-30599 | Reserved for apps | Available |

---

## Related

- [[Nodes/S740-Master|S740 Implementation Guide]]
- [[Network/VLAN-Setup|VLAN Configuration]]
- [[Runbooks/Quick-Commands|Quick Commands]]
- [[Runbooks/Flux-Commands|Flux Commands]]
- [[Nodes/Synology-Worker|Synology Worker (Planned)]]

## Tags

#homelab #k3s #flux #gitops #infrastructure
