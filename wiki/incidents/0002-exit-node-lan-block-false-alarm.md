---
id: "0002"
title: "Cluster 'down' was really a Tailscale exit node blocking LAN access"
status: done
created: 2026-07-16
updated: 2026-07-16
links: ["[[incidents/0001]]", "[[runbooks/0002]]"]
---
## Symptom
`kubectl` timed out and `10.10.10.10:6443` looked down — identical to [[incidents/0001]].
This time **all three hosts** (`.10`, `.20`, `.39`) appeared unreachable, including
`k3s-node-01` which had been rock-solid all session. The Homelab VLAN gateway `10.10.10.1`
still pinged.

## Root cause
Not the cluster — the **Mac's** network path. A Tailscale **exit node** (`ai-connector`,
Singapore) was active with `ExitNodeAllowLANAccess=false`. Tailscale's default blocks direct
LAN access while an exit node is engaged (an anti-leak safeguard), so `10.10.10.x` became
unreachable even though the Mac literally sat on that subnet (`en0 = 10.10.10.232`). The
default route was `utun8` (Tailscale).

## Evidence
- `route -n get default` → `interface: utun8`.
- `ifconfig en0` → `10.10.10.232` (on the Homelab VLAN); `ping 10.10.10.1` OK.
- `tailscale debug prefs` → `ExitNodeID` set, `ExitNodeAllowLANAccess: False`.
- The tell vs a real outage: **node-01 also went dark**. In the real IP-flip outage only the
  master was unreachable; here *everything* on the subnet was, because the block is on the
  client side.

## Resolution
`tailscale set --exit-node-allow-lan-access=true` — keeps the exit node, restores LAN
access. `10.10.10.10:6443` immediately OPEN; both nodes `Ready`.

## Recurrence risk / follow-ups
Will recur whenever the exit node is toggled on. Not worth "fixing" (the exit node is
wanted), just recognizing. Distinguishing rule captured in [[runbooks/0002]]: **check
`tailscale debug prefs` before assuming the master died** — especially when *node-01* is also
unreachable, which points at the client, not the cluster.
