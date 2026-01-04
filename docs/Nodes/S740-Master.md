# S740 K3s Master Node

Implementation guide for K3s control plane on Fujitsu S740.

## Node Information

| Property | Value |
|----------|-------|
| **Hostname** | k3s-master |
| **IP Address** | 10.10.10.10 |
| **MAC Address** | 4c:52:62:1f:9e:49 |
| **OS** | Ubuntu 24.04.1 LTS |
| **K3s Version** | v1.34.3+k3s1 |
| **Role** | Control Plane (master) |
| **CPU** | Intel Celeron J4105 (4C/4T) |
| **RAM** | 4 GB |
| **Storage** | 512 GB SSD |
| **Power** | PoE (Power over Ethernet) |

## Access

```bash
# SSH
ssh ubuntu@10.10.10.10

# Kubectl (from Mac)
export KUBECONFIG=~/.kube/config-s740
kubectl get nodes
```

---

## Implementation Steps

### Phase 1: USB Preparation (Mac)

```bash
# Flash Ubuntu 24.04.1 LTS to USB
./flash-usb.sh list
./flash-usb.sh flash /dev/diskN
```

### Phase 2: Ubuntu Installation (S740)

1. Insert USB into S740
2. Power on, press **F12** for boot menu
3. Select USB drive
4. Installation choices:

| Screen | Selection |
|--------|-----------|
| Installation type | Ubuntu Server (not minimized) |
| Network | DHCP (configure static later) |
| Storage | Use entire disk (LVM) |
| Profile | hostname: `k3s-master`, user: `ubuntu` |
| SSH | ✅ Install OpenSSH server |
| Snaps | Skip all (we use K3s, not MicroK8s) |

> **Note:** If installation hangs on downloads (linux-firmware 539MB), press Close and Reboot - core system is installed.

### Phase 3: Network Configuration

After Ubuntu boots, configure static IP:

```bash
ssh ubuntu@<dhcp-ip>
sudo nano /etc/netplan/50-cloud-init.yaml
```

```yaml
network:
  version: 2
  ethernets:
    eno1:
      addresses:
        - 10.10.10.10/24
      routes:
        - to: default
          via: 10.10.10.1
      nameservers:
        addresses: [10.10.10.1, 8.8.8.8]
```

```bash
sudo netplan apply
```

Reconnect: `ssh ubuntu@10.10.10.10`

### Phase 4: SSH Key Setup

From Mac:

```bash
# Copy SSH key to S740
ssh-copy-id ubuntu@10.10.10.10

# Test passwordless SSH
ssh ubuntu@10.10.10.10
```

### Phase 5: SSH Agent Sudo (Secure)

On S740:

```bash
# Install PAM module
sudo apt update
sudo apt install -y libpam-ssh-agent-auth

# Copy SSH key to root
sudo mkdir -p /root/.ssh
sudo cp ~/.ssh/authorized_keys /root/.ssh/
sudo chmod 600 /root/.ssh/authorized_keys

# Configure PAM - add to TOP of /etc/pam.d/sudo:
sudo nano /etc/pam.d/sudo
```

Add as first line:
```
auth sufficient pam_ssh_agent_auth.so file=/root/.ssh/authorized_keys
```

Configure sudoers:
```bash
sudo visudo
```

Add line:
```
Defaults    env_keep += "SSH_AUTH_SOCK"
```

### Phase 6: K3s Installation

From Mac:

```bash
# Ensure SSH agent has key
ssh-add -l
ssh-add ~/.ssh/id_rsa  # if empty

# Install K3s with agent forwarding
ssh -A -t ubuntu@10.10.10.10 "curl -sfL https://get.k3s.io | sudo sh -s - server --disable=traefik --write-kubeconfig-mode=644"
```

### Phase 7: Kubeconfig Setup

From Mac:

```bash
# Create .kube directory
mkdir -p ~/.kube

# Get kubeconfig
ssh -A ubuntu@10.10.10.10 "sudo cat /etc/rancher/k3s/k3s.yaml" > ~/.kube/config-s740

# Fix server IP
sed -i '' 's/127.0.0.1/10.10.10.10/g' ~/.kube/config-s740

# Set permissions
chmod 600 ~/.kube/config-s740

# Make permanent
echo 'export KUBECONFIG=~/.kube/config-s740' >> ~/.zshrc
source ~/.zshrc

# Test
kubectl get nodes
```

---

## Verification

```bash
# Check node status
kubectl get nodes

# Expected output:
# NAME         STATUS   ROLES           AGE   VERSION
# k3s-master   Ready    control-plane   Xm    v1.34.3+k3s1

# Check all pods
kubectl get pods -A
```

---

## Maintenance Commands

### Node Operations

```bash
# SSH to node
ssh ubuntu@10.10.10.10

# Reboot node
ssh ubuntu@10.10.10.10 "sudo reboot"

# Check disk space
ssh ubuntu@10.10.10.10 "df -h"

# Check memory
ssh ubuntu@10.10.10.10 "free -h"
```

### K3s Operations

```bash
# K3s status (on node)
sudo systemctl status k3s

# K3s logs (on node)
sudo journalctl -u k3s -f

# Restart K3s (on node)
sudo systemctl restart k3s

# Update K3s (on node)
curl -sfL https://get.k3s.io | sudo sh -
```

### Kubectl from Mac

```bash
export KUBECONFIG=~/.kube/config-s740

kubectl get nodes
kubectl get pods -A
kubectl get events -A --sort-by='.lastTimestamp'
```

---

## Troubleshooting

### Can't SSH to node

```bash
# Check connectivity
ping 10.10.10.10

# Check if on same VLAN or inter-VLAN routing works
# Mac should be on Homelab WiFi (10.10.10.x)
```

### Kubectl connection refused

```bash
# Ensure KUBECONFIG is set
echo $KUBECONFIG

# Should show: /Users/<you>/.kube/config-s740

# If blank, set it:
export KUBECONFIG=~/.kube/config-s740
```

### K3s not running

```bash
ssh ubuntu@10.10.10.10
sudo systemctl status k3s
sudo journalctl -u k3s -n 50
```

---

## Related

- [[Network/VLAN-Setup|VLAN Configuration]]
- [[Runbooks/Quick-Commands|Quick Commands]]
- [[Nodes/Synology-Worker|Synology Worker (Future)]]

## Tags

#homelab #k3s #s740 #implementation
