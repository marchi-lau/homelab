# Synology Worker Node (Planned)

Future K3s worker node running as VM on Synology DS1821+.

## Planned Configuration

| Property | Value |
|----------|-------|
| **Hostname** | k3s-worker-syn |
| **IP Address** | 10.10.10.20 |
| **Role** | K3s Worker |
| **vCPU** | 2 cores |
| **RAM** | 8 GB |
| **Disk** | 32 GB |
| **Host** | Synology DS1821+ (64GB RAM) |

---

## Architecture

```
┌──────────────────┐         ┌────────────────────────────────┐
│  S740 (Master)   │         │      Synology DS1821+          │
│  10.10.10.10     │         │                                │
│                  │         │  ┌──────────────────────────┐  │
│  • K3s Server    │◄───────►│  │  Ubuntu VM (Worker)      │  │
│  • Control Plane │  K3s    │  │  10.10.10.20             │  │
│                  │         │  │                          │  │
│                  │         │  │  • n8n                   │  │
│                  │         │  │  • Supabase              │  │
│                  │         │  └───────────┬──────────────┘  │
│                  │         │              │ NFS             │
│                  │         │  ┌───────────▼──────────────┐  │
│                  │         │  │  /volume1/k8s-data       │  │
│                  │         │  │  10.10.10.50             │  │
│                  │         │  └──────────────────────────┘  │
└──────────────────┘         └────────────────────────────────┘
```

---

## Implementation Steps (TODO)

### 1. Create NFS Share on Synology

- Shared folder: `k3s-data`
- NFS permissions for 10.10.10.0/24
- Path: `/volume1/k3s-data`

### 2. Create Ubuntu VM in VMM

- Name: `k3s-worker-syn`
- OS: Ubuntu 24.04 LTS
- CPU: 2 cores
- RAM: 8 GB
- Disk: 32 GB
- Network: Homelab VLAN

### 3. Configure Static IP

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      addresses: [10.10.10.20/24]
      routes:
        - to: default
          via: 10.10.10.1
      nameservers:
        addresses: [10.10.10.1, 8.8.8.8]
```

### 4. Join K3s Cluster

```bash
# Get token from master
ssh ubuntu@10.10.10.10 "sudo cat /var/lib/rancher/k3s/server/node-token"

# On Synology VM
curl -sfL https://get.k3s.io | K3S_URL=https://10.10.10.10:6443 K3S_TOKEN=<token> sh -
```

### 5. Setup NFS StorageClass

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: synology-nfs
provisioner: nfs.csi.k8s.io
parameters:
  server: 10.10.10.50
  share: /volume1/k8s-data
```

---

## Benefits

| Benefit | Explanation |
|---------|-------------|
| Heavy compute | 8GB RAM for workloads |
| S740 stays light | Control plane only |
| NFS storage | RAID protected |
| Easy expansion | Add more workers later |

---

## Related

- [[Nodes/S740-Master|S740 Master]]
- [[Network/VLAN-Setup|Network Setup]]

## Tags

#homelab #synology #future #planning
