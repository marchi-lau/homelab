#!/bin/bash
#
# Setup Synology Worker VM
# Usage: ./setup-synology-worker.sh <DHCP_IP>
#
# This script configures a fresh Ubuntu VM to be a K3s worker node.
# Run this after Ubuntu installation while VM still has DHCP IP.
#

set -e

DHCP_IP="${1:-}"
STATIC_IP="10.10.10.20"
GATEWAY="10.10.10.1"
HOSTNAME="k3s-node-01"
USER="ubuntu"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# Check arguments
if [[ -z "$DHCP_IP" ]]; then
    echo "Usage: $0 <DHCP_IP>"
    echo "  DHCP_IP: Current IP address of the VM (from DHCP)"
    echo ""
    echo "Example: $0 10.10.10.100"
    exit 1
fi

echo "========================================"
echo "  Synology Worker VM Setup"
echo "========================================"
echo ""
echo "  Current IP:  $DHCP_IP"
echo "  Target IP:   $STATIC_IP"
echo "  Hostname:    $HOSTNAME"
echo ""

# Test connectivity
log "Testing connectivity to $DHCP_IP..."
if ! ping -c 1 -W 2 "$DHCP_IP" &>/dev/null; then
    error "Cannot reach $DHCP_IP. Check VM is running and on correct network."
fi

# Copy SSH key
log "Copying SSH key to VM..."
if ! ssh-copy-id -o StrictHostKeyChecking=accept-new "$USER@$DHCP_IP" 2>/dev/null; then
    warn "SSH key copy failed (may already exist). Continuing..."
fi

# Test SSH
log "Testing SSH connection..."
if ! ssh -o BatchMode=yes "$USER@$DHCP_IP" "echo 'SSH OK'" &>/dev/null; then
    error "Cannot SSH to $DHCP_IP. Run: ssh-copy-id $USER@$DHCP_IP"
fi

# Detect network interface name
log "Detecting network interface..."
IFACE=$(ssh "$USER@$DHCP_IP" "ip route | grep default | awk '{print \$5}' | head -1")
log "Found interface: $IFACE"

# Configure static IP
log "Configuring static IP ($STATIC_IP)..."
ssh "$USER@$DHCP_IP" "sudo tee /etc/netplan/50-static.yaml > /dev/null" <<EOF
network:
  version: 2
  ethernets:
    $IFACE:
      addresses:
        - $STATIC_IP/24
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses: [$GATEWAY, 8.8.8.8]
EOF

# Disable cloud-init network config
ssh "$USER@$DHCP_IP" "sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg > /dev/null" <<EOF
network: {config: disabled}
EOF

# Remove old netplan configs that might conflict
ssh "$USER@$DHCP_IP" "sudo rm -f /etc/netplan/00-installer-config.yaml /etc/netplan/50-cloud-init.yaml 2>/dev/null || true"

# Set hostname
log "Setting hostname to $HOSTNAME..."
ssh "$USER@$DHCP_IP" "sudo hostnamectl set-hostname $HOSTNAME"
ssh "$USER@$DHCP_IP" "echo '127.0.1.1 $HOSTNAME' | sudo tee -a /etc/hosts > /dev/null"

# Update system
log "Updating system packages..."
ssh "$USER@$DHCP_IP" "sudo apt-get update -qq && sudo apt-get upgrade -y -qq"

# Install required packages
log "Installing required packages..."
ssh "$USER@$DHCP_IP" "sudo apt-get install -y -qq nfs-common libpam-ssh-agent-auth curl open-iscsi"

# Setup SSH agent sudo
log "Configuring SSH agent sudo..."
ssh "$USER@$DHCP_IP" "sudo mkdir -p /root/.ssh && sudo cp ~/.ssh/authorized_keys /root/.ssh/ && sudo chmod 600 /root/.ssh/authorized_keys"

# Configure PAM for SSH agent auth
ssh "$USER@$DHCP_IP" "sudo sed -i '1i auth sufficient pam_ssh_agent_auth.so file=/root/.ssh/authorized_keys' /etc/pam.d/sudo"

# Configure sudoers for SSH_AUTH_SOCK
ssh "$USER@$DHCP_IP" "echo 'Defaults env_keep += \"SSH_AUTH_SOCK\"' | sudo tee /etc/sudoers.d/ssh-agent > /dev/null"

# Apply netplan and reboot
log "Applying network configuration and rebooting..."
warn "VM will reboot and come up at $STATIC_IP"
ssh "$USER@$DHCP_IP" "sudo netplan apply 2>/dev/null; sudo reboot" || true

echo ""
echo "========================================"
echo "  Setup Complete!"
echo "========================================"
echo ""
echo "  VM is rebooting..."
echo "  New IP: $STATIC_IP"
echo ""
echo "  Wait ~60 seconds, then run:"
echo "    ./scripts/join-k3s-cluster.sh $STATIC_IP"
echo ""
