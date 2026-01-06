# Add Synology Worker Node to K3s

Step-by-step guide for adding Synology DS1821+ as K3s worker node.

## Prerequisites

- [ ] Synology DS1821+ accessible on network
- [ ] VMM (Virtual Machine Manager) package installed on Synology
- [ ] Ubuntu 24.04 LTS ISO downloaded to Synology
- [ ] Mac connected to Homelab network (10.10.10.x)

## Overview

| Step | Task | Type |
|------|------|------|
| 1 | Create NFS share on Synology | Manual (DSM GUI) |
| 2 | Create Ubuntu VM in VMM | Manual (DSM GUI) |
| 3 | Install Ubuntu on VM | Manual (VM console) |
| 4 | Configure VM networking | **Automated** |
| 5 | Setup SSH keys | **Automated** |
| 6 | Join K3s cluster | **Automated** |
| 7 | Deploy NFS StorageClass | **Automated** |
| 8 | Verify cluster | **Automated** |

---

## Step 1: Create NFS Share (Manual - DSM GUI)

1. Open **DSM** → **Control Panel** → **Shared Folder**
2. Click **Create** → **Create Shared Folder**
3. Configure:
   - Name: `k3s-data`
   - Location: Volume 1
   - ✅ Enable data checksum
4. Click **Next** until done

5. Open **Control Panel** → **File Services** → **NFS**
6. ✅ Enable NFS service
7. Go back to **Shared Folder** → Select `k3s-data` → **Edit** → **NFS Permissions**
8. Click **Create**:
   - Hostname/IP: `10.10.10.0/24`
   - Privilege: Read/Write
   - Squash: Map all users to admin
   - ✅ Allow connections from non-privileged ports
   - ✅ Allow users to access mounted subfolders
9. Click **OK**

**Note the NFS path:** `/volume1/k3s-data`

---

## Step 2: Create Ubuntu VM (Manual - VMM)

1. Open **VMM** (Virtual Machine Manager)
2. Click **Create** → **Create Virtual Machine**
3. Select **Linux**
4. Configure:

| Setting | Value |
|---------|-------|
| Name | k3s-worker-syn |
| CPU | 4 cores |
| RAM | 16 GB |
| Disk | 64 GB |
| Network | Homelab VLAN |
| ISO | ubuntu-24.04-live-server-amd64.iso |

5. Click **Create**
6. Start the VM and open console

---

## Step 3: Install Ubuntu (Manual - VM Console)

1. Boot from ISO, select **Install Ubuntu Server**
2. Configure:

| Screen | Selection |
|--------|-----------|
| Language | English |
| Keyboard | US |
| Network | DHCP (for now) |
| Storage | Use entire disk |
| Profile | hostname: `k3s-worker-syn`, user: `ubuntu` |
| SSH | ✅ Install OpenSSH server |
| Snaps | Skip all |

3. Wait for installation to complete
4. Reboot (remove ISO from VMM)
5. Note the DHCP IP address shown on console

---

## Step 4: Configure VM Networking (Automated)

Once Ubuntu is installed and you have the DHCP IP:

```bash
# Run from Mac - replace <DHCP_IP> with actual IP
./scripts/setup-synology-worker.sh <DHCP_IP>
```

<details>
<summary>What this script does</summary>

1. Copies SSH key to the VM
2. Configures static IP (10.10.10.20)
3. Sets hostname to `k3s-worker-syn`
4. Installs required packages
5. Configures SSH agent sudo
6. Reboots to apply network changes

</details>

---

## Step 5-7: Join Cluster & Setup NFS (Automated)

After the VM reboots with new IP (10.10.10.20):

```bash
# Run from Mac
./scripts/join-k3s-cluster.sh 10.10.10.20
```

<details>
<summary>What this script does</summary>

1. Gets K3s token from master node
2. Joins VM to K3s cluster as agent
3. Waits for node to be Ready
4. Deploys NFS CSI driver
5. Creates `synology-nfs` StorageClass
6. Verifies cluster status

</details>

---

## Step 8: Verification (Automated)

```bash
# Check nodes
KUBECONFIG=~/.kube/config-s740 kubectl get nodes

# Expected output:
# NAME              STATUS   ROLES                  AGE   VERSION
# k3s-master        Ready    control-plane,master   Xd    v1.34.3+k3s1
# k3s-worker-syn    Ready    <none>                 Xm    v1.34.3+k3s1

# Check StorageClass
KUBECONFIG=~/.kube/config-s740 kubectl get sc

# Test NFS PVC
KUBECONFIG=~/.kube/config-s740 kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-nfs-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: synology-nfs
  resources:
    requests:
      storage: 1Gi
EOF

# Check PVC bound
KUBECONFIG=~/.kube/config-s740 kubectl get pvc test-nfs-pvc

# Cleanup test
KUBECONFIG=~/.kube/config-s740 kubectl delete pvc test-nfs-pvc
```

---

## Quick Reference

| Item | Value |
|------|-------|
| VM Name | k3s-node-01 |
| VM IP | 10.10.10.20 |
| VM User | ubuntu |
| NFS Server | 10.10.10.100 |
| NFS Path | /volume3/k3s-data |
| StorageClass | synology-nfs |

---

## Troubleshooting

### VM can't get DHCP IP
- Check VMM network is set to Homelab VLAN
- Verify VLAN tagging in Synology network settings

### Can't SSH to VM after static IP
```bash
# Check if IP is reachable
ping 10.10.10.20

# If not, access VM console in VMM and check netplan
sudo cat /etc/netplan/50-static.yaml
sudo netplan apply
```

### SSH agent sudo not working
**Symptom**: `ssh -A ubuntu@10.10.10.20 'sudo whoami'` prompts for password

**Root cause**: 1Password SSH agent forwards different key than `authorized_keys`

**Solution**:
```bash
# 1. Check which key is being forwarded
ssh -A ubuntu@10.10.10.20 'ssh-add -L'

# 2. Override IdentityAgent for homelab hosts in ~/.ssh/config:
Host 10.10.10.*
    IdentityAgent /private/tmp/com.apple.launchd.*/Listeners
    ForwardAgent yes
    IdentityFile ~/.ssh/id_rsa
    User ubuntu

# 3. Copy RSA key to root's authorized_keys
ssh ubuntu@10.10.10.20 'sudo mkdir -p /root/.ssh && sudo cp ~/.ssh/authorized_keys /root/.ssh/'

# 4. Test
ssh -A ubuntu@10.10.10.20 'sudo whoami'  # Should return "root"
```

### K3s installs as server instead of agent
**Symptom**: `systemctl status k3s` shows K3s server running, not agent

**Root cause**: K3S_URL and K3S_TOKEN not properly passed to install script

**Solution**:
```bash
# Clean up existing K3s installation
sudo /usr/local/bin/k3s-uninstall.sh

# Install correctly with environment variables exported
export K3S_URL='https://10.10.10.10:6443'
export K3S_TOKEN='your-token-here'
curl -sfL https://get.k3s.io | sudo -E sh -

# Verify agent is running
sudo systemctl status k3s-agent
```

### K3s API unresponsive / timeout during join
**Symptom**: `curl -k https://10.10.10.10:6443` hangs or times out

**Root cause**: Master node under memory pressure (check swap usage)

**Solution**:
```bash
# Check swap on master
ssh ubuntu@10.10.10.10 'free -h'

# Restart K3s on master
ssh ubuntu@10.10.10.10 'sudo systemctl restart k3s'

# Wait 30s, then retry join
```

### NFS mount timeout / no route to host
**Symptom**: `mount.nfs: Connection timed out`

**Diagnosis**:
```bash
# From master node, test connectivity to Synology
ssh ubuntu@10.10.10.10 'ping -c 3 10.10.10.100'

# If fails, check network/VLAN configuration
# Synology and K3s nodes must be on same VLAN or routable
```

### NFS mount fails with "No such file or directory"
**Symptom**: `mount.nfs: mounting 10.10.10.100:/volume1/k3s-data failed, reason given by server: No such file or directory`

**Diagnosis**:
```bash
# Discover available NFS shares
ssh ubuntu@10.10.10.10 'showmount -e 10.10.10.100'

# Common issue: wrong volume path
# /volume1/ vs /volume3/ - check which volume the share is on
```

### NFS mount fails with "wrong fs type"
**Symptom**: `mount: /mnt: wrong fs type, bad option, bad superblock`

**Root cause**: Missing `nfs-common` package

**Solution**:
```bash
# Install on ALL nodes that need NFS
ssh ubuntu@10.10.10.10 'sudo apt-get update && sudo apt-get install -y nfs-common'
ssh ubuntu@10.10.10.20 'sudo apt-get update && sudo apt-get install -y nfs-common'
```

### PVC stuck in Pending state
```bash
# Check CSI driver pods
kubectl get pods -n kube-system -l app=csi-nfs-controller

# Check StorageClass
kubectl get sc synology-nfs -o yaml

# Check events
kubectl describe pvc <pvc-name>
```

---

## Automation Improvements

### Lessons Learned

The manual process encountered several issues that could be prevented:

| Issue | Root Cause | Prevention |
|-------|------------|------------|
| SSH agent sudo fails | 1Password agent vs RSA key mismatch | Pre-configure `~/.ssh/config` for homelab hosts |
| K3s installs as server | Environment variables not passed | Use explicit `K3S_URL=... K3S_TOKEN=... curl | sudo -E sh -` |
| NFS mount fails | Wrong IP/path, missing packages | Add preflight checks to script |
| K3s API timeout | Master under memory pressure | Add health check before join |

### Recommended Script Improvements

Update `scripts/setup-synology-worker.sh` to include:

```bash
# 1. Pre-flight checks
preflight_checks() {
    echo "Running pre-flight checks..."

    # Check SSH config for homelab hosts
    if ! grep -q "Host 10.10.10.*" ~/.ssh/config; then
        error "Missing homelab SSH config. Add to ~/.ssh/config:

Host 10.10.10.*
    IdentityAgent /private/tmp/com.apple.launchd.*/Listeners
    ForwardAgent yes
    IdentityFile ~/.ssh/id_rsa
    User ubuntu"
    fi

    # Check RSA key exists
    if [[ ! -f ~/.ssh/id_rsa ]]; then
        error "RSA key not found at ~/.ssh/id_rsa"
    fi

    # Verify correct key is being used (not 1Password)
    if ssh-add -L 2>/dev/null | grep -q "1Password"; then
        warn "1Password key detected. Ensure homelab hosts use correct agent."
    fi
}

# 2. Network validation
validate_network() {
    echo "Validating network connectivity..."

    # Check master reachable
    if ! ping -c 1 "$MASTER_IP" &>/dev/null; then
        error "Cannot reach master at $MASTER_IP"
    fi

    # Check K3s API responsive
    if ! curl -sk --connect-timeout 5 "https://$MASTER_IP:6443" &>/dev/null; then
        error "K3s API not responding at $MASTER_IP:6443. Try: ssh ubuntu@$MASTER_IP 'sudo systemctl restart k3s'"
    fi

    # Check NFS server reachable from master
    if ! ssh "$USER@$MASTER_IP" "ping -c 1 $NFS_SERVER" &>/dev/null; then
        error "Master cannot reach NFS server at $NFS_SERVER. Check VLAN configuration."
    fi

    # Discover and validate NFS path
    NFS_SHARES=$(ssh "$USER@$MASTER_IP" "showmount -e $NFS_SERVER 2>/dev/null" || true)
    if [[ -z "$NFS_SHARES" ]]; then
        error "Cannot query NFS shares from $NFS_SERVER. Is NFS enabled on Synology?"
    fi
    if ! echo "$NFS_SHARES" | grep -q "$NFS_PATH"; then
        error "NFS path $NFS_PATH not found. Available shares:\n$NFS_SHARES"
    fi
}

# 3. Ensure nfs-common installed on all nodes
ensure_nfs_packages() {
    for node in "$MASTER_IP" "$WORKER_IP"; do
        if ! ssh "$USER@$node" "dpkg -l | grep -q nfs-common" 2>/dev/null; then
            log "Installing nfs-common on $node..."
            ssh "$USER@$node" "sudo apt-get update && sudo apt-get install -y nfs-common"
        fi
    done
}

# 4. Setup root authorized_keys for SSH agent sudo
setup_root_ssh() {
    ssh "$USER@$WORKER_IP" "sudo mkdir -p /root/.ssh && sudo cp ~/.ssh/authorized_keys /root/.ssh/ && sudo chmod 600 /root/.ssh/authorized_keys"
}
```

### Future: Full Automation with Ansible

For repeatable worker node additions, consider:

1. **Ansible playbook** for VM configuration
2. **cloud-init** user-data for Ubuntu installation
3. **Terraform** for VMM VM provisioning (if Synology API supports it)

Example Ansible structure:
```
ansible/
├── inventory/
│   └── homelab.yml
├── playbooks/
│   └── add-k3s-worker.yml
└── roles/
    ├── base/           # Common packages, SSH config
    ├── k3s-agent/      # K3s agent installation
    └── nfs-client/     # NFS client setup
```

### Validation Checklist

Before running join script, verify:

- [ ] `~/.ssh/config` has homelab host configuration
- [ ] RSA key exists at `~/.ssh/id_rsa`
- [ ] `ssh -A ubuntu@WORKER_IP 'sudo whoami'` returns `root`
- [ ] Master API responds: `curl -sk https://10.10.10.10:6443`
- [ ] Master can ping NFS server: `ssh ubuntu@MASTER_IP 'ping -c 1 NFS_IP'`
- [ ] NFS share path confirmed: `ssh ubuntu@MASTER_IP 'showmount -e NFS_IP'`
- [ ] `nfs-common` installed on master

---

## Related

- [[Nodes/S740-Master|S740 Master Node]]
- [[Nodes/Synology-Worker|Synology Worker Planning]]
- [[Network/VLAN-Setup|VLAN Configuration]]

## Tags

#homelab #synology #k3s #runbook
