---
id: "0005"
title: "Flux source-controller and NFS CSI sidecars chronically crash-looping"
status: active
created: 2026-07-16
updated: 2026-07-16
links: ["[[architectures/0002]]"]
---
## Symptom
`flux-system/source-controller` `0/1 CrashLoopBackOff` (~51 restarts). `kube-system/
csi-nfs-controller` `2/5` with the `csi-provisioner`, `csi-resizer`, `csi-snapshotter`
sidecars at ~900 restarts **each** (2791 total on the pod). Intermittent `kubectl` TLS
handshake timeouts against the API server throughout the session.

## Root cause
**Master memory pressure.** `k3s-master` is a 4GB box (`kubectl top node` → ~2952Mi / 80%).
`source-controller`'s `manager` exits 1 under memory pressure. The CSI `nfs` driver
container itself is healthy — but the three sidecars run **leader election against the
apiserver**, and against an apiserver that's memory-starved and throwing TLS timeouts, the
leases expire and the sidecars die and retry endlessly. Existing NFS volumes still mount
(the driver is fine); only *new* PVC provisioning/resizing/snapshots are impaired.

## Evidence
- `kubectl top node k3s-master` → 80% memory on 4GB.
- `source-controller` container `manager`: `exit=1 reason=Error`.
- CSI: healthy containers = `nfs`, `liveness-probe`; crashing = `csi-provisioner/resizer/
  snapshotter` (all leader-election sidecars).
- Repeated `net/http: TLS handshake timeout` from the apiserver during normal `kubectl`.

## Resolution
None applied — these are **symptoms of an undersized control-plane node**, not independent
bugs. A config tweak would be a band-aid. See [[architectures/0002]] for the real
remediation options (relocate master-pinned workloads to node-01, taint the master
control-plane-only, or add RAM).

## Recurrence risk / follow-ups
Ongoing until master capacity is addressed. Highest-leverage low-risk step: move the
Prometheus + Uptime-Kuma pods (currently pinned to master) onto node-01 (24GB, ~51% used)
to free master memory. Tracked in [[architectures/0002]].
