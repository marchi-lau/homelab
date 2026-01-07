#!/bin/bash
#
# Join K3s Cluster and Setup NFS StorageClass
# Usage: ./join-k3s-cluster.sh <WORKER_IP>
#
# This script:
# 1. Gets K3s token from master
# 2. Joins worker to cluster
# 3. Deploys NFS CSI driver
# 4. Creates synology-nfs StorageClass
#

set -e

WORKER_IP="${1:-10.10.10.20}"
MASTER_IP="10.10.10.10"
NFS_SERVER="10.10.10.100"  # Synology DS1821+ NAS
NFS_PATH="/volume3/k3s-data"
USER="ubuntu"
KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config-s740}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

echo "========================================"
echo "  K3s Cluster Join"
echo "========================================"
echo ""
echo "  Master:  $MASTER_IP"
echo "  Worker:  $WORKER_IP"
echo "  NFS:     $NFS_SERVER:$NFS_PATH"
echo ""

# Check KUBECONFIG
if [[ ! -f "$KUBECONFIG" ]]; then
    error "KUBECONFIG not found at $KUBECONFIG"
fi
export KUBECONFIG

# Test connectivity to worker
log "Testing connectivity to worker ($WORKER_IP)..."
if ! ping -c 1 -W 2 "$WORKER_IP" &>/dev/null; then
    error "Cannot reach $WORKER_IP. Is the VM running with static IP?"
fi

# Test SSH to worker
log "Testing SSH to worker..."
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$USER@$WORKER_IP" "echo 'SSH OK'" &>/dev/null; then
    error "Cannot SSH to $WORKER_IP"
fi

# Test connectivity to master
log "Testing connectivity to master ($MASTER_IP)..."
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$USER@$MASTER_IP" "echo 'SSH OK'" &>/dev/null; then
    error "Cannot SSH to master at $MASTER_IP"
fi

# Get K3s token from master
log "Getting K3s token from master..."
K3S_TOKEN=$(ssh -A "$USER@$MASTER_IP" "sudo cat /var/lib/rancher/k3s/server/node-token")
if [[ -z "$K3S_TOKEN" ]]; then
    error "Failed to get K3s token from master"
fi
log "Token retrieved successfully"

# Check if already joined
info "Checking if worker is already in cluster..."
if kubectl get node "$( ssh "$USER@$WORKER_IP" "hostname" )" &>/dev/null; then
    warn "Worker is already in cluster. Skipping K3s install."
else
    # Install K3s agent on worker
    log "Installing K3s agent on worker..."
    ssh -A "$USER@$WORKER_IP" "curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN='$K3S_TOKEN' sudo sh -"

    # Wait for node to appear
    log "Waiting for node to join cluster..."
    for i in {1..30}; do
        if kubectl get node "$( ssh "$USER@$WORKER_IP" "hostname" )" &>/dev/null; then
            break
        fi
        echo -n "."
        sleep 2
    done
    echo ""
fi

# Wait for node to be Ready
log "Waiting for node to be Ready..."
WORKER_HOSTNAME=$(ssh "$USER@$WORKER_IP" "hostname")
for i in {1..60}; do
    STATUS=$(kubectl get node "$WORKER_HOSTNAME" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
    if [[ "$STATUS" == "True" ]]; then
        log "Node $WORKER_HOSTNAME is Ready!"
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

# Verify node status
kubectl get nodes

echo ""
echo "========================================"
echo "  Setting up NFS StorageClass"
echo "========================================"
echo ""

# Check if NFS CSI driver is already installed
if kubectl get pods -n kube-system -l app=csi-nfs-controller &>/dev/null 2>&1 && \
   kubectl get pods -n kube-system -l app=csi-nfs-controller -o jsonpath='{.items[0].status.phase}' 2>/dev/null | grep -q "Running"; then
    warn "NFS CSI driver already installed. Skipping..."
else
    # Install NFS CSI driver
    log "Installing NFS CSI driver..."
    helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts 2>/dev/null || true
    helm repo update csi-driver-nfs

    helm upgrade --install csi-driver-nfs csi-driver-nfs/csi-driver-nfs \
        --namespace kube-system \
        --set controller.replicas=1 \
        --wait
fi

# Create StorageClass
log "Creating synology-nfs StorageClass..."
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: synology-nfs
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: nfs.csi.k8s.io
parameters:
  server: $NFS_SERVER
  share: $NFS_PATH
reclaimPolicy: Delete
volumeBindingMode: Immediate
mountOptions:
  - nfsvers=4.1
EOF

log "StorageClass created"

# Show StorageClasses
kubectl get sc

echo ""
echo "========================================"
echo "  Setup Complete!"
echo "========================================"
echo ""
echo "  Cluster nodes:"
kubectl get nodes
echo ""
echo "  StorageClasses:"
kubectl get sc
echo ""
echo "  Test with:"
echo "    kubectl apply -f - <<EOF"
echo "    apiVersion: v1"
echo "    kind: PersistentVolumeClaim"
echo "    metadata:"
echo "      name: test-nfs"
echo "    spec:"
echo "      storageClassName: synology-nfs"
echo "      accessModes: [ReadWriteMany]"
echo "      resources:"
echo "        requests:"
echo "          storage: 1Gi"
echo "    EOF"
echo ""
