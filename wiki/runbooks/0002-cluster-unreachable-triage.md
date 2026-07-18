---
id: "0002"
title: "Triage 'cluster unreachable' — client-side vs real outage"
status: active
created: 2026-07-16
updated: 2026-07-16
links: ["[[incidents/0002]]", "[[incidents/0004]]", "[[runbooks/0001]]"]
---
## When to use
`kubectl` times out / `10.10.10.10:6443` looks down. Decide *before* touching the cluster
whether the problem is your Mac or the master.

## Prerequisites
Local `tailscale`, `ping`, `nc`. `export KUBECONFIG=~/.kube/config-s740`.

## Steps
1. **Scan all hosts:** `nc -z` / `ping` `.10`, `.20`, `.39`.
   - Only the **master** unreachable, node-01 fine ⇒ real master problem → [[runbooks/0001]].
   - **All three (incl. node-01)** unreachable ⇒ almost certainly **client-side**.
2. **Check the Tailscale exit node** (the usual client-side culprit):
   ```
   route -n get default | grep interface        # utun8 => routing via Tailscale
   tailscale debug prefs | grep -E 'ExitNode|LanAccess'
   ```
   If `ExitNodeID` is set and `ExitNodeAllowLANAccess: False`, that's it — see
   [[incidents/0002]].
3. **Fix (keeps the exit node):** `tailscale set --exit-node-allow-lan-access=true`.
4. Re-test: `nc -z -G 3 10.10.10.10 6443` → OPEN; `kubectl get nodes`.

## Verification
`kubectl get nodes` returns both nodes `Ready`.

## Notes / gotchas
- Confirm you're actually on the Homelab VLAN first: `ifconfig en0` should show a
  `10.10.10.x` address and `ping 10.10.10.1` (gateway) should succeed.
- **Corrupt containerd layer cleanup** (after a master hard-crash, if pods on master hit
  ImagePull `failed precondition`): SSH to the node and
  `sudo k3s ctr content prune references` (or remove the specific bad image). See
  [[incidents/0004]].
