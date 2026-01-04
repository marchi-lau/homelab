# VLAN Setup

UniFi network configuration for Homelab.

## Network Overview

| Network | VLAN ID | Subnet | Gateway | Purpose |
|---------|---------|--------|---------|---------|
| Default | 1 | 192.168.1.0/24 | 192.168.1.1 | Home devices |
| **Homelab** | **10** | **10.10.10.0/24** | **10.10.10.1** | **K3s cluster** |

---

## Homelab Network Configuration

### UniFi Settings

| Setting | Value |
|---------|-------|
| **Network Name** | Homelab |
| **VLAN ID** | 10 |
| **Gateway/Subnet** | 10.10.10.1/24 |
| **DHCP Range** | 10.10.10.100 - 10.10.10.199 |
| **Domain** | homelab.local (optional) |

### Creation Steps

1. **Settings** → **Networks** → **+ Create New**
2. Name: `Homelab`
3. Gateway IP/Subnet: `10.10.10.1/24`
4. Advanced → VLAN ID: `10`
5. DHCP Range: `10.10.10.100` - `10.10.10.199`
6. **Add Network**

---

## Static IP Assignments

| Device | MAC Address | IP | Status |
|--------|-------------|-----|--------|
| S740 Master | 4c:52:62:1f:9e:49 | 10.10.10.10 | ✅ Active |
| Synology NAS | TBD | 10.10.10.50 | 📋 Planned |
| Synology VM | TBD | 10.10.10.20 | 📋 Planned |

### Add Static IP in UniFi

1. **Settings** → **Networks** → **Homelab** → **Edit**
2. **DHCP Service Management** → **Static IP**
3. **+ Add Static IP**
4. MAC: `4c:52:62:1f:9e:49`
5. IP: `10.10.10.10`
6. Name: `k3s-master`

---

## IP Allocation Plan

| Range | Purpose |
|-------|---------|
| 10.10.10.1 | Gateway (UniFi) |
| 10.10.10.2-9 | Reserved (future infra) |
| 10.10.10.10-19 | K3s Nodes |
| 10.10.10.20-29 | VMs |
| 10.10.10.50-59 | NAS/Storage |
| 10.10.10.100-199 | DHCP Pool |
| 10.10.10.200-254 | Services/VIPs |

---

## Switch Port Configuration

For wired devices on Homelab VLAN:

1. **Devices** → **Your Switch** → **Ports**
2. Select port where S740 is connected
3. **Port Profile** → **Homelab**
4. **Apply**

> **Note:** S740 uses PoE - do not disconnect ethernet (kills power)

---

## WiFi for Homelab VLAN

Created WiFi network on Homelab VLAN for Mac access:

1. **Settings** → **WiFi** → **Create New**
2. Name: `Homelab`
3. Network: `Homelab` (VLAN 10)
4. Security: WPA3

Connect Mac to "Homelab" WiFi to access 10.10.10.x devices directly.

---

## Inter-VLAN Routing

UniFi allows inter-VLAN routing by default.

To access K3s from default network (if needed):
- Ensure no firewall rules blocking LAN → LAN traffic
- **Settings** → **Firewall & Security** → **Firewall Rules**

---

## Troubleshooting

### Can't reach 10.10.10.10

```bash
# Check your Mac's IP
ifconfig en0 | grep inet

# Should be 10.10.10.x if on Homelab WiFi

# Ping gateway first
ping 10.10.10.1

# Then ping S740
ping 10.10.10.10
```

### Device on wrong VLAN

1. Check switch port profile in UniFi
2. Or check WiFi network connected

### No DHCP

1. Verify DHCP is enabled on Homelab network
2. Check DHCP range is set

---

## Related

- [[Nodes/S740-Master|S740 Master Node]]
- [[Runbooks/Quick-Commands|Quick Commands]]

## Tags

#homelab #network #vlan #unifi
