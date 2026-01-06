# Synology Worker Node

K3s worker node running as VM on Synology DS1821+.

## Configuration

| Property | Value |
|----------|-------|
| **Hostname** | k3s-node-01 |
| **IP Address** | 10.10.10.20 |
| **Role** | K3s Worker (Agent) |
| **vCPU** | 4 cores |
| **RAM** | 24 GB |
| **Disk** | 64 GB |
| **OS** | Ubuntu 24.04.3 LTS |
| **K3s Version** | v1.34.3+k3s1 |
| **Host** | Synology DS1821+ (64GB RAM) |
| **Video Card** | vga (not vmvga - causes blank screen) |
| **Network Interface** | ens3 |

---

## Architecture

```
┌──────────────────┐         ┌────────────────────────────────────────┐
│  S740 (Master)   │         │        Synology DS1821+ (10.10.10.100) │
│  10.10.10.10     │         │                                        │
│                  │         │  ┌────────────────────────────────┐    │
│  • K3s Server    │◄───────►│  │  Ubuntu VM (Worker)            │    │
│  • Control Plane │  K3s    │  │  k3s-node-01 / 10.10.10.20     │    │
│  • Flux GitOps   │  API    │  │                                │    │
│  • CF Tunnel     │         │  │  • K3s Agent                   │    │
│                  │         │  │  • 4 vCPU, 24GB RAM            │    │
│                  │         │  │  • NFS CSI node driver         │    │
│                  │         │  └───────────┬────────────────────┘    │
│                  │         │              │ NFS v4.1                │
│                  │         │  ┌───────────▼────────────────────┐    │
│                  │         │  │  /volume3/k3s-data             │    │
│                  │         │  │  synology-nfs StorageClass     │    │
│                  │         │  └────────────────────────────────┘    │
└──────────────────┘         └────────────────────────────────────────┘
```

---

## NFS Storage

| Property | Value |
|----------|-------|
| NFS Server | 10.10.10.100 |
| NFS Share | /volume3/k3s-data |
| NFS Version | 4.1 |
| StorageClass | synology-nfs |
| Provisioner | nfs.csi.k8s.io |
| Access Mode | ReadWriteMany (RWX) |

### StorageClass Definition

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: synology-nfs
provisioner: nfs.csi.k8s.io
parameters:
  server: 10.10.10.100
  share: /volume3/k3s-data
reclaimPolicy: Delete
volumeBindingMode: Immediate
mountOptions:
  - nfsvers=4.1
```

---

## Network Configuration

### Static IP (Netplan)

```yaml
# /etc/netplan/50-static.yaml
network:
  version: 2
  ethernets:
    ens3:
      addresses:
        - 10.10.10.20/24
      routes:
        - to: default
          via: 10.10.10.1
      nameservers:
        addresses: [10.10.10.1, 8.8.8.8]
```

### SSH Agent Sudo

Passwordless sudo via SSH agent forwarding is configured:

| File | Purpose |
|------|---------|
| `/etc/pam.d/sudo` | `auth sufficient pam_ssh_agent_auth.so file=/root/.ssh/authorized_keys` |
| `/etc/sudoers.d/ssh-agent` | `Defaults env_keep += "SSH_AUTH_SOCK"` |
| `/root/.ssh/authorized_keys` | Contains RSA public key from Mac |

**Mac SSH Config** (`~/.ssh/config`):
```
Host 10.10.10.*
    IdentityAgent /private/tmp/com.apple.launchd.*/Listeners
    ForwardAgent yes
    IdentityFile ~/.ssh/id_rsa
    User ubuntu
```

---

## Installed Packages

- `nfs-common` - NFS client utilities
- `open-iscsi` - iSCSI initiator (for future use)
- `libpam-ssh-agent-auth` - SSH agent PAM module
- `curl` - HTTP client

---

## Verification Commands

```bash
# Check node status
KUBECONFIG=~/.kube/config-s740 kubectl get nodes

# Check K3s agent service
ssh ubuntu@10.10.10.20 'sudo systemctl status k3s-agent'

# Check NFS CSI driver on node
KUBECONFIG=~/.kube/config-s740 kubectl get pods -n kube-system -l app.kubernetes.io/instance=csi-driver-nfs -o wide

# Test NFS mount manually
ssh ubuntu@10.10.10.20 'sudo mount -t nfs -o nfsvers=4.1 10.10.10.100:/volume3/k3s-data /mnt && ls /mnt && sudo umount /mnt'

# Test SSH agent sudo
ssh -A ubuntu@10.10.10.20 'sudo whoami'  # Should return "root" without password
```

---

## Known Issues

### VMM Video Card
- **Issue**: Ubuntu 24.04 shows blank screen with default `vmvga` video card
- **Solution**: Change video card to `vga` in VMM settings before Ubuntu installation

### 1Password SSH Agent Conflict
- **Issue**: Mac uses 1Password SSH agent which forwards different key than `authorized_keys`
- **Solution**: Override `IdentityAgent` in `~/.ssh/config` for homelab hosts

### K3s API Timeout During Join
- **Issue**: K3s master API can become unresponsive under memory pressure
- **Solution**: Restart K3s on master: `ssh ubuntu@10.10.10.10 'sudo systemctl restart k3s'`

---

## Related

- [[Nodes/S740-Master|S740 Master Node]]
- [[Network/VLAN-Setup|Network Setup]]
- [[Runbooks/Add-Synology-Worker|Add Worker Runbook]]

## Tags

#homelab #synology #k3s #worker #ubuntu
