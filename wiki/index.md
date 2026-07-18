# Wiki — homelab K3s GitOps

LLM-maintained knowledge base for this cluster (see `wiki/*/.prompt` for each folder's
schema). Humans rarely edit this; the `retro` skill maintains it. Raw sources stay
authoritative and are linked, never absorbed:
- `clusters/homelab/apps/*.yaml` — the deployed manifests (source of truth for services).
- `docs/` — Obsidian docs: `docs/Homelab.md`, `docs/Nodes/`, `docs/Network/`,
  `docs/Runbooks/`, `docs/Apps/`, `specs/`.

## services/
One doc per deployed workload. See [[services/.prompt]].
- [[services/0001]] — croc: private tailnet-only file-transfer relay.
- [[services/0002]] — firecrawl: self-hosted web scraping/crawl service.
- [[services/0003]] — AEM author instances (`aem` + `rosewood-aem`).

## incidents/
Outages, crash-loops, and false alarms with root cause + resolution. See [[incidents/.prompt]].
- [[incidents/0001]] — **active** — master IP flipped to `.39` on reboot, broke the cluster.
- [[incidents/0002]] — done — "cluster down" was a Tailscale exit node blocking LAN access.
- [[incidents/0003]] — done — firecrawl OOM at 2Gi masking a 60s harness startup timeout.
- [[incidents/0004]] — done — ai-drawio ImagePullBackOff from a corrupt containerd layer.
- [[incidents/0005]] — **active** — Flux/CSI controllers flapping under 4GB-master pressure.

## architectures/
Cluster-wide decisions and constraints. See [[architectures/.prompt]].
- [[architectures/0001]] — expose private TCP via the Tailscale operator (not hostNetwork/NodePort).
- [[architectures/0002]] — the 4GB master is the root fragility behind most incidents.
- [[architectures/0003]] — GitOps flow: Flux tracks `main`; live patches aren't durable.

## runbooks/
Repeatable operational procedures. See [[runbooks/.prompt]].
- [[runbooks/0001]] — recover the master after a crash / unreachable control plane.
- [[runbooks/0002]] — triage 'cluster unreachable': client-side vs real outage.
- [[runbooks/0003]] — **draft** — pin the master to `10.10.10.10` so a reboot can't flip its IP.
- [[runbooks/0004]] — deploy/change a service via GitOps and force a Flux sync.

## Pre-existing unmanaged content
None under `wiki/` (this is the first scaffold). Existing `docs/` and `specs/` trees remain
outside the wiki and are linked from the docs above.
