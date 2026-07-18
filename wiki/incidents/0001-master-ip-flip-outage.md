---
id: "0001"
title: "Master node IP flipped to 10.10.10.39 on reboot, breaking the cluster"
status: active
created: 2026-07-16
updated: 2026-07-16
links: ["[[runbooks/0001]]", "[[runbooks/0003]]", "[[architectures/0002]]", "[[incidents/0002]]"]
---
## Symptom
After a master (`k3s-master`) reboot, the API server at `10.10.10.10:6443` was unreachable.
`ping 10.10.10.10` returned `Host is down` (ARP-level, not a TCP timeout), SSH:22 dead.
`k3s-node-01` (10.10.10.20) stayed reachable on the same subnet, so it was isolated to the
master host. The master had come back on a **different address, `10.10.10.39`**, where
`:6443` listened but rejected the existing kubeconfig with `Unauthorized` even under
`--insecure-skip-tls-verify`.

## Root cause
The master's NIC had **multiple IPs** and no pinned node-IP, so K3s chose its node-IP /
apiserver advertise address non-deterministically at boot. It ran as `.10` for months, then
grabbed `.39` after this reboot. `.39` is **outside the DHCP pool** (`10.10.10.100-199` per
`docs/Network/VLAN-Setup.md`), so the intended static reservation for MAC
`4c:52:62:1f:9e:49 → 10.10.10.10` was not holding. Everything is hard-wired to `.10` — the
kubeconfig, node-01's agent (`--server https://10.10.10.10:6443`), and the apiserver cert
SANs — so when the IP moved, node registration and credentials broke.

## Evidence
- `ping: sendto: Host is down` on `.10` while `.20` answered in ~7ms → host-specific, not network.
- `linode`/subnet scan found the live apiserver on `.39`.
- `kubectl --server=https://10.10.10.39:6443 --insecure-skip-tls-verify` → `Unauthorized`
  (server rejected the client cert → cluster identity tied to the `.10` install).
- Recovery only completed once the box was restored to `10.10.10.10`.

## Resolution
Restoring the master to `10.10.10.10` healed everything with zero reconfiguration (node-01
rejoined, kubeconfig worked, traefik re-advertised `.10`). Confirmed later: master `Ready`
at `10.10.10.10`, both nodes up.

## Recurrence risk / follow-ups
**NOT yet hardened.** The durable fix — pin the node-IP so K3s can't guess again — was never
applied. Until done, another reboot can flip the IP and repeat this outage. See
[[runbooks/0003]] (pin static IP: netplan + `--node-ip` + UniFi reservation) and
[[architectures/0002]] (the 4GB-master fragility this is part of). Recovery procedure:
[[runbooks/0001]]. A later same-symptom event turned out to be a different cause entirely —
see [[incidents/0002]].
