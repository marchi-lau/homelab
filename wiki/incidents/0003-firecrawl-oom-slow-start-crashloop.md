---
id: "0003"
title: "firecrawl CrashLoopBackOff — OOM at 2Gi masking a 60s harness startup timeout"
status: done
created: 2026-07-16
updated: 2026-07-16
links: ["[[services/0002]]", "[[runbooks/0004]]"]
---
## Symptom
`firecrawl-api` container in `CrashLoopBackOff` for ~150 days (4/5 containers ready). Pod
otherwise healthy (playwright, postgres, rabbitmq, redis all up).

## Root cause
**Two stacked failures.** (1) The single `firecrawl-api` container runs ~11 Node.js worker
processes (`api`, `worker`, `extract-worker`, 5× `nuq-worker`, prefetch, reconciler); their
aggregate RSS exceeded the **2Gi** memory limit → `OOMKilled` (exit 137) ~43s into boot.
(2) Once given more memory it instead exited 1 with `Port 3002 did not become available
within 60000ms` — the all-in-one image's harness aborts if the api doesn't bind `:3002`
within `HARNESS_STARTUP_TIMEOUT_MS` (default **60000**), and the boot storm needs longer.
The OOM was firing *before* the 60s timer, hiding the second problem.

## Evidence
- `lastState.terminated`: `reason=OOMKilled exit=137` at 2Gi.
- After a live bump to 4Gi: `reason=Error exit=1`, logs showed the harness `Port 3002 did
  not become available within 60000ms` at `/app/dist/src/harness.js`.
- `HARNESS_STARTUP_TIMEOUT_MS` confirmed in the image: `z.coerce.number().default(60000)`.

## Resolution
Committed to `clusters/homelab/apps/firecrawl.yaml` (GitOps; live patches get reverted by
Flux): memory limit **2Gi → 4Gi**, `HARNESS_STARTUP_TIMEOUT_MS=300000`, **plus a
`startupProbe`** (30×10s = 5min). The startupProbe was essential: the existing
`livenessProbe` (initialDelay 90s) would SIGKILL the pod mid-boot before the 300s harness
window completed — i.e. without it we'd have swapped an OOM loop for a liveness loop. After
Flux sync the pod reached **5/5 Running** (1 early restart, then bound `:3002` at ~3m30s)
and served HTTP 200.

## Recurrence risk / follow-ups
Durable — the fix is in git. Deploy pattern used: [[runbooks/0004]]. Service doc:
[[services/0002]]. General lesson: exit 137 = OOM (kernel SIGKILL); raising a limit can
*unmask* a slower failure, so re-check after every layer you fix.
