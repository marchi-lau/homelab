---
id: "0002"
title: "The 4GB master is the root fragility behind most cluster incidents"
status: active
created: 2026-07-16
updated: 2026-07-16
links: ["[[incidents/0001]]", "[[incidents/0005]]", "[[runbooks/0003]]"]
---
## Context
`k3s-master` (Fujitsu S740) has only **4GB RAM** and runs the full control plane **plus**
scheduled workloads (Prometheus and Uptime-Kuma are pinned to it). `kubectl top node`
shows it steadily at ~80% memory. `k3s-node-01` is a 24GB VM at ~51%.

## Decision
Recognized (not yet remediated) that the undersized, overloaded master is the common cause
behind multiple incidents this session, and that the fix is a **capacity/placement** change,
not per-symptom patches.

## Consequences
Under memory pressure the master exhibits: slow/failed boots, intermittent apiserver TLS
handshake timeouts, and control-plane controllers crash-looping (Flux `source-controller`,
CSI leader-election sidecars — [[incidents/0005]]). The hard crashes it suffered also left a
corrupt containerd layer ([[incidents/0004]]) and contributed to the IP-flip outage
([[incidents/0001]]).

## Constraints honored
- Workloads on node-01 keep running when the control plane is degraded (they did during the
  outage), but nothing can be scheduled/changed until the master recovers.
- NFS volumes still mount when CSI sidecars flap (the driver container stays up); only new
  PVC provisioning is affected.

## Alternatives considered / remediation options (ranked)
1. **Free master RAM (fastest, no hardware):** relocate the master-pinned Prometheus +
   Uptime-Kuma to node-01 (24GB, ~51% used). Highest leverage, lowest risk — should stop the
   controller flapping. GitOps change.
2. **Taint the master** `control-plane:NoSchedule` so only control-plane components run there.
3. **Add RAM to the S740** — durable fix; 4GB is very tight for a K3s server.
4. Separately, **pin the master node-IP** ([[runbooks/0003]]) so reboots can't flip the
   address — orthogonal to capacity but part of hardening the same node.
