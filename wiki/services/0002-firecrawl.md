---
id: "0002"
title: "firecrawl — self-hosted web scraping/crawl service"
status: active
created: 2026-07-16
updated: 2026-07-16
links: ["[[incidents/0003]]"]
---
## Summary
Self-hosted firecrawl (all-in-one image) for web scraping/crawl/extract, exposed to
in-cluster consumers and via Tailscale. The single `firecrawl-api` container is actually a
supervisor running ~11 Node.js worker processes plus sidecar containers (playwright,
postgres, rabbitmq, redis) in one pod.

## Deployment
- Namespace `firecrawl`; manifest `clusters/homelab/apps/firecrawl.yaml`.
- `firecrawl-api` container: memory **request 512Mi / limit 4Gi** (raised from 2Gi — see
  below), plus `HARNESS_STARTUP_TIMEOUT_MS=300000` and a `startupProbe` (30×10s).
- Service `firecrawl:3002` (ClusterIP). Also has a Tailscale Ingress (`firecrawl.tailb1bee0.ts.net`).

## Exposure
ClusterIP `firecrawl:3002` for pod-to-pod; Tailscale Ingress for private external access.
In-cluster consumers must use internal DNS `http://firecrawl.firecrawl.svc.cluster.local:3002`.

## Operational notes
- **Slow, memory-heavy startup.** The ~11 workers push aggregate RSS past 2Gi and the boot
  takes >60s. Required config: 4Gi limit + `HARNESS_STARTUP_TIMEOUT_MS=300000` + a
  `startupProbe` so the k8s `livenessProbe` doesn't SIGKILL it mid-boot. Full story:
  [[incidents/0003]].
- Live `kubectl patch` changes are reverted by Flux — fixes must be committed to the manifest.
- Note: there is also a separate `mcp-firecrawl` (public firecrawl MCP) in `.mcp.json`; this
  self-hosted instance is distinct and was down for ~150d without anyone noticing because the
  hosted MCP was being used.

## Related
[[incidents/0003]] (the OOM + slow-start crash-loop and its fix).
