# Homelab

K3s Kubernetes cluster on Fujitsu S740 + Synology NAS with Flux GitOps and Cloudflare Tunnel.

## Quick Links

- [[Nodes/S740-Master|S740 Master Node]] - Control plane implementation
- [[Nodes/Synology-Worker|Synology Worker Node]] - Worker node on DS1821+ VM
- [[Network/VLAN-Setup|VLAN Configuration]]
- [[Network/Cloudflare-Tunnel|Cloudflare Tunnel Setup]]
- [[Network/Tailscale-Operator|Tailscale Operator (Private Ingress)]]
- [[Runbooks/Quick-Commands|Quick Commands]]
- [[Runbooks/Flux-Commands|Flux GitOps Commands]]
- [[Runbooks/Add-Synology-Worker|Add Worker Node Runbook]]
- [[Apps/n8n|n8n Workflow Automation]]
- [[Apps/rustfs|RustFS S3 Storage]]
- [[Apps/Monitoring|Prometheus + Grafana Monitoring]]
- [[Apps/string-is|string-is String Toolkit]]
- [[Apps/it-tools|IT-Tools Developer Toolkit]]
- [[Apps/s-pdf|Stirling PDF Toolkit]]
- [[Apps/uptime-kuma|Uptime Kuma Status Monitoring]]
- [[Apps/homepage|Homepage Dashboard]]
- [[Apps/ai-drawio|AI Draw.io Diagram Editor]]
- [[Apps/mcp-cloudflare|MCP Cloudflare (Private)]]

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│  Internet                                                                        │
│      │                                                                           │
│      ▼                                                                           │
│  ┌──────────────────────┐                                                        │
│  │   Cloudflare Edge    │  ◄── WAF, DDoS protection, SSL                        │
│  │  *.marchi.app        │                                                        │
│  └──────────┬───────────┘                                                        │
│             │ Encrypted tunnel (outbound only)                                   │
│             ▼                                                                    │
│  ┌────────────────────────────────────────────────────────────────────────────┐  │
│  │                        Homelab Network (VLAN 10)                           │  │
│  │                            10.10.10.0/24                                   │  │
│  │                                                                            │  │
│  │  ┌──────────────────┐         ┌────────────────────────────────────────┐   │  │
│  │  │  S740 (Master)   │         │        Synology DS1821+ (10.10.10.100) │   │  │
│  │  │  10.10.10.10     │         │                                        │   │  │
│  │  │                  │         │  ┌────────────────────────────────┐    │   │  │
│  │  │  ✅ K3s Server   │◄───────►│  │  Ubuntu VM (Worker)            │    │   │  │
│  │  │  ✅ Control Plane│  K3s    │  │  k3s-node-01 / 10.10.10.20     │    │   │  │
│  │  │  ✅ Flux GitOps  │  API    │  │                                │    │   │  │
│  │  │  ✅ CF Tunnel    │         │  │  ✅ K3s Agent                  │    │   │  │
│  │  │                  │         │  │  ✅ 4 vCPU, 24GB RAM           │    │   │  │
│  │  │                  │         │  │  ✅ NFS CSI node driver        │    │   │  │
│  │  │                  │         │  └───────────┬────────────────────┘    │   │  │
│  │  │                  │         │              │ NFS v4.1                │   │  │
│  │  │                  │         │  ┌───────────▼────────────────────┐    │   │  │
│  │  │                  │         │  │  /volume3/k3s-data             │    │   │  │
│  │  │                  │         │  │  synology-nfs StorageClass     │    │   │  │
│  │  │                  │         │  └────────────────────────────────┘    │   │  │
│  │  └────────┬─────────┘         └────────────────────────────────────────┘   │  │
│  │           │                                                                │  │
│  │           ▼                                                                │  │
│  │  ┌─────────────────┐                                                       │  │
│  │  │  GitHub Repo    │◄──── Flux syncs every 10m                             │  │
│  │  │  marchi-lau/    │                                                       │  │
│  │  │  homelab        │                                                       │  │
│  │  └─────────────────┘                                                       │  │
│  └────────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## Current Status

| Component | Status | Details |
|-----------|--------|---------|
| **S740 Master** | ✅ Running | K3s v1.34.3, 10.10.10.10, control-plane |
| **Synology Worker** | ✅ Running | K3s v1.34.3, 10.10.10.20, k3s-node-01 |
| **Flux GitOps** | ✅ Running | v2.7.5, syncing from GitHub |
| **Cloudflare Tunnel** | ✅ Running | Ingress controller + cloudflared |
| **NFS Storage** | ✅ Running | synology-nfs StorageClass, 10.10.10.100:/volume3/k3s-data |
| **n8n** | ✅ Running | https://n8n-02.marchi.app |
| **GitHub Repo** | ✅ Active | [marchi-lau/homelab](https://github.com/marchi-lau/homelab) |

---

## Deployed Apps

| App | URL | Namespace | Node | Storage |
|-----|-----|-----------|------|---------|
| **n8n** | https://n8n-02.marchi.app | n8n | Master | 5Gi PVC |
| **RustFS** | https://s3.marchi.app / https://s3-console.marchi.app | rustfs | Any | 10Gi NFS |
| **Grafana** | https://grafana.marchi.app | monitoring | Worker | 1Gi PVC |
| **Prometheus** | (internal) | monitoring | Master | 5Gi PVC |
| **string-is** | https://string-is.marchi.app | string-is | Any | None |
| **IT-Tools** | https://it-tools.marchi.app | it-tools | Any | None |
| **Stirling PDF** | https://s-pdf.marchi.app | s-pdf | Any | None |
| **Uptime Kuma** | https://status.marchi.app | uptime-kuma | Master | 1Gi PVC |
| **Homepage** | https://homepage.marchi.app | homepage | Any | None |
| **AI Draw.io** | https://diagram.marchi.app | ai-drawio | Any | None |
| **MCP Cloudflare** | https://mcp-cloudflare.tailb1bee0.ts.net | mcp-cloudflare | Any | None |
| **MCP Airtable** | https://mcp-airtable.tailb1bee0.ts.net | mcp-airtable | Worker | None |

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
| grafana.marchi.app | kube-prometheus-stack-grafana:80 | monitoring |
| string-is.marchi.app | string-is:3000 | string-is |
| it-tools.marchi.app | it-tools:80 | it-tools |
| s-pdf.marchi.app | s-pdf:8080 | s-pdf |
| status.marchi.app | uptime-kuma:3001 | uptime-kuma |
| homepage.marchi.app | homepage:3000 | homepage |
| diagram.marchi.app | ai-drawio:3000 | ai-drawio |

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

### Phase 1: Core Infrastructure ✅
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
- [x] Prometheus + Grafana monitoring stack (Helm)

### Phase 2: Synology Worker Node ✅
- [x] Synology DS1821+ NFS share (/volume3/k3s-data)
- [x] Ubuntu 24.04 VM in VMM (4 vCPU, 24GB RAM)
- [x] VM static IP configuration (10.10.10.20)
- [x] SSH agent sudo on worker
- [x] K3s agent joined to cluster
- [x] NFS CSI driver installed
- [x] synology-nfs StorageClass created and tested

### Phase 3: Future
- [ ] Cloudflare WAF bypass rule
- [ ] High availability (multiple masters)
- [ ] Backup automation

---

## Repository Structure

```
homelab/
├── clusters/
│   └── homelab/
│       ├── apps/                    # Application manifests
│       │   ├── n8n.yaml
│       │   ├── rustfs.yaml
│       │   ├── monitoring.yaml
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

| Device | Model | RAM | Role | IP | Status |
|--------|-------|-----|------|-----|--------|
| S740 | Fujitsu S740 | 4GB | K3s Master | 10.10.10.10 | ✅ Running |
| Synology | DS1821+ | 64GB | NAS + VM Host | 10.10.10.100 | ✅ Running |
| k3s-node-01 | VM on DS1821+ | 24GB | K3s Worker | 10.10.10.20 | ✅ Running |

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

- [[Nodes/S740-Master|S740 Master Node]]
- [[Nodes/Synology-Worker|Synology Worker Node]]
- [[Network/VLAN-Setup|VLAN Configuration]]
- [[Network/Cloudflare-Tunnel|Cloudflare Tunnel Setup]]
- [[Apps/n8n|n8n App]]
- [[Runbooks/Quick-Commands|Quick Commands]]
- [[Runbooks/Flux-Commands|Flux Commands]]
- [[Runbooks/Add-Synology-Worker|Add Worker Node Runbook]]

## Tags

#homelab #k3s #flux #gitops #cloudflare #infrastructure
