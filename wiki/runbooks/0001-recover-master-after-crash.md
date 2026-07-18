---
id: "0001"
title: "Recover the master after a crash / unreachable control plane"
status: active
created: 2026-07-16
updated: 2026-07-16
links: ["[[incidents/0001]]", "[[runbooks/0002]]", "[[runbooks/0003]]"]
---
## When to use
`k3s-master` (10.10.10.10) is unreachable — API `:6443` down, SSH down, `ping` says
`Host is down` — but `k3s-node-01` (10.10.10.20) still answers. (First rule out the
client-side false alarm: [[runbooks/0002]].)

## Prerequisites
- `export KUBECONFIG=~/.kube/config-s740`.
- Out-of-band access: GL.iNet KVM devices on the tailnet — `glkvm` (100.67.64.107) and
  `glkvm-1` (100.111.120.17). The master is **not** a tailnet node, so it can only be reached
  on the LAN or via KVM console.

## Steps
1. Confirm scope: `ping`/`nc -z` `.10`, `.20`, and `.39`. Master-only unreachable + node-01
   fine ⇒ master host problem. If it moved to another address (e.g. `.39`), that's the
   IP-flip: [[incidents/0001]].
2. If fully dark (no ping/SSH on any address) after a reboot for >4 min, **stop blind
   polling** and open the KVM console (`ssh root@100.67.64.107` or the web UI) to see where
   it's stuck (POST / GRUB / fsck / panic / login).
3. Restore it to **`10.10.10.10`** — everything (kubeconfig, node-01 agent, cert SANs) is
   wired to that address; restoring it heals the cluster with no reconfiguration.
4. If it came back on a wrong IP, fix the address (netplan/UniFi) — [[runbooks/0003]].

## Verification
```
export KUBECONFIG=~/.kube/config-s740
kubectl get nodes -o wide          # both Ready, master INTERNAL-IP = 10.10.10.10
kubectl get pods -A | grep -vE 'Running|Completed'
```

## Notes / gotchas
- `Host is down` is ARP-level (host absent), more severe than a TCP timeout.
- Do **not** reboot repeatedly if it's a netplan error — a reboot won't fix it; read the
  console first.
- Post-recovery, check for corrupt containerd layers from the hard crash ([[runbooks/0002]]).
