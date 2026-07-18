---
id: "0004"
title: "ai-drawio ImagePullBackOff — corrupt containerd layer on the crashed master"
status: done
created: 2026-07-16
updated: 2026-07-16
links: ["[[incidents/0001]]", "[[runbooks/0002]]"]
---
## Symptom
`ai-drawio` pod in `ImagePullBackOff` for ~170 days, pinned to `k3s-master`. Not an auth or
missing-tag error.

## Root cause
A **corrupt layer in the master's containerd content store**:
`failed to pull and unpack ... unexpected commit digest sha256:18bd... expected
sha256:242...: failed precondition`. containerd rejected a blob whose computed digest didn't
match — a half-written layer left by an interrupted pull, almost certainly collateral from
the master's earlier **hard crashes** (see [[incidents/0001]]). Node-01's content store was
clean.

## Evidence
- `kubectl describe pod` → the digest-mismatch `failed precondition` (not `unauthorized` /
  `not found`).
- Pod was scheduled on `k3s-master`, the node that crashed hard.
- Deleting the pod → it rescheduled to `k3s-node-01`, pulled cleanly, went `1/1 Running`.

## Resolution
`kubectl delete pod -n ai-drawio -l app=ai-drawio` → scheduler placed it on node-01 (clean
store) → healthy immediately. Non-destructive; no manifest change needed.

## Recurrence risk / follow-ups
The **corrupt blob still sits in master's content store**, so any pod scheduled there that
needs that layer will fail again. Prune it via SSH: `sudo k3s ctr content prune references`
(or remove the specific bad image). Captured as a step in [[runbooks/0002]]. Lesson: after
an unclean node shutdown, ImagePull `failed precondition`/digest-mismatch errors point at a
corrupt content store, not the registry — reschedule to another node as the fast unblock.
