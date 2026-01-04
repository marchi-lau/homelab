# Homelab

K3s Kubernetes cluster on Fujitsu S740 + Synology NAS with Flux GitOps and Cloudflare Tunnel.

## Quick Links

- [[Nodes/S740-Master|S740 Master Node]] - Implementation guide
- [[Network/VLAN-Setup|VLAN Configuration]]
- [[Network/Cloudflare-Tunnel|Cloudflare Tunnel Setup]]
- [[Runbooks/Quick-Commands|Quick Commands]]
- [[Runbooks/Flux-Commands|Flux GitOps Commands]]
- [[Apps/n8n|n8n Workflow Automation]]
- [[Apps/rustfs|RustFS S3 Storage]]

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Internet                                                                │
│      │                                                                   │
│      ▼                                                                   │
│  ┌──────────────────────┐                                                │
│  │   Cloudflare Edge    │  ◄── WAF, DDoS protection, SSL                │
│  │  n8n-02.marchi.app   │                                                │
│  └──────────┬───────────┘                                                │
│             │ Encrypted tunnel (outbound only)                           │
│             ▼                                                            │
│  ┌──────────────────────────────────────────────────────────────────┐    │
│  │                   Homelab Network (VLAN 10)                      │    │
│  │                       10.10.10.0/24                              │    │
│  │                                                                  │    │
│  │   ┌─────────────────┐       ┌──────────────────────────────────┐│    │
│  │   │  S740 Master    │       │     Synology DS1821+ (Future)   ││    │
│  │   │  10.10.10.10    │       │                                  ││    │
│  │   │                 │       │  ⏳ VM Worker: 10.10.10.20       ││    │
│  │   │  ✅ K3s Server  │       │  ⏳ NFS Storage: 10.10.10.50     ││    │
│  │   │  ✅ Flux GitOps │       │     64GB RAM                     ││    │
│  │   │  ✅ CF Tunnel   │       │                                  ││    │
│  │   │  ✅ n8n         │       └──────────────────────────────────┘│    │
│  │   └────────┬────────┘                                           │    │
│  │            │                                                    │    │
│  │            ▼                                                    │    │
│  │   ┌─────────────────┐                                           │    │
│  │   │  GitHub Repo    │◄──── Flux syncs every 10m                 │    │
│  │   │  marchi-lau/    │                                           │    │
│  │   │  homelab        │                                           │    │
│  │   └─────────────────┘                                           │    │
│  └──────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Current Status

| Component | Status | Details |
|-----------|--------|---------|
| **S740 Master** | ✅ Running | K3s v1.34.3, 10.10.10.10 |
| **Flux GitOps** | ✅ Running | v2.7.5, syncing from GitHub |
| **Cloudflare Tunnel** | ✅ Running | Ingress controller + cloudflared |
| **n8n** | ✅ Running | https://n8n-02.marchi.app |
| **GitHub Repo** | ✅ Active | [marchi-lau/homelab](https://github.com/marchi-lau/homelab) |
| Synology Worker | ⏳ Planned | VM on DS1821+ |
| NFS Storage | ⏳ Planned | Synology share |

---

## Deployed Apps

| App | URL | Namespace | Storage |
|-----|-----|-----------|---------|
| **n8n** | https://n8n-02.marchi.app | n8n | 5Gi PVC |
| **RustFS** | https://s3.marchi.app (API) / https://s3-console.marchi.app (Console) | rustfs | 10Gi PVC |

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

# Check ingresses
kubectl get ingress -A

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
| Tunnel Name | homelab-k3s |

---

## Ingress (Cloudflare Tunnel)

Services are exposed via Cloudflare Tunnel Ingress Controller. No open ports required.

| Host | Service | Namespace |
|------|---------|-----------|
| n8n-02.marchi.app | n8n:5678 | n8n |
| s3.marchi.app | rustfs:9000 | rustfs |
| s3-console.marchi.app | rustfs:9001 | rustfs |

To expose a new service, add an Ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  namespace: myapp
spec:
  ingressClassName: cloudflare-tunnel
  rules:
    - host: myapp.marchi.app
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myapp
                port:
                  number: 8080
```

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
- [x] Helm installed
- [x] Cloudflare Tunnel Ingress Controller
- [x] n8n deployment
- [ ] Cloudflare WAF bypass rule
- [ ] Synology VM worker node
- [ ] NFS StorageClass

---

## Repository Structure

```
homelab/
├── clusters/
│   └── homelab/
│       ├── apps/                    # Application manifests
│       │   ├── n8n.yaml
│       │   └── kustomization.yaml
│       └── flux-system/             # Flux components
│           ├── gotk-components.yaml
│           ├── gotk-sync.yaml
│           ├── apps-kustomization.yaml
│           └── kustomization.yaml
├── docs/                            # Documentation (Obsidian)
├── .mcp.json                        # Claude Code MCP config
├── CLAUDE.md                        # Agent instructions
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

| Item      | Value            |     |
| --------- | ---------------- | --- |
| VLAN Name | Homelab          |     |
| VLAN ID   | 10               |     |
| Subnet    | 10.10.10.0/24    |     |
| Gateway   | 10.10.10.1       |     |
| WiFi      | "Homelab" (WPA3) |     |

---

## Related

- [[Nodes/S740-Master|S740 Implementation Guide]]
- [[Network/VLAN-Setup|VLAN Configuration]]
- [[Network/Cloudflare-Tunnel|Cloudflare Tunnel Setup]]
- [[Apps/n8n|n8n App]]
- [[Runbooks/Quick-Commands|Quick Commands]]
- [[Runbooks/Flux-Commands|Flux Commands]]
- [[Nodes/Synology-Worker|Synology Worker (Planned)]]

## Tags

#homelab #k3s #flux #gitops #cloudflare #infrastructure
