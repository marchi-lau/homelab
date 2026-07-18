---
id: "0001"
title: "Expose private TCP services via the Tailscale operator, not hostNetwork/NodePort"
status: active
created: 2026-07-16
updated: 2026-07-16
links: ["[[services/0001]]"]
---
## Context
The croc relay needs **fixed, real ports 9009-9013** reachable privately. Three exposure
mechanisms exist on this cluster: Cloudflare tunnel (public HTTP), Tailscale Ingress
(private HTTP/HTTPS only), and the Tailscale **operator** Service annotation (private, raw
TCP). croc is raw multi-port TCP, so the HTTP-only paths don't apply.

## Decision
Expose raw private TCP services by annotating a plain ClusterIP Service with
`tailscale.com/expose: "true"` (+ `hostname`, `tags: tag:kubernetes`). The operator creates
a dedicated tailnet **device** carrying the service's real ports. Used for croc
([[services/0001]]); the pre-existing `ai-workstation` (SSH/22) proves the pattern.

## Consequences
- The service gets its own `100.x` address + MagicDNS name with the **actual** port numbers
  (no NodePort `30000-32767` remap).
- **Zero LAN exposure** — traffic only arrives over the tailnet; access is governed entirely
  by the Tailscale ACL.
- No host changes and **no node needs to join the tailnet** (none currently do).

## Constraints honored
- **NodePort can't be used**: it only allocates `30000-32767`, but croc clients must reach
  the literal `9009-9013`.
- **hostNetwork/hostPort would leak**: they bind `0.0.0.0` — every node interface — so the
  ports would also listen on the LAN (`10.10.10.x`), which a Tailscale ACL cannot block.
- **Tag must be `tag:kubernetes`** — the tag the operator already owns/assigns. A new tag
  (e.g. `tag:croc-relay`) fails `tagOwners: does not exist` because the operator's OAuth
  client is scoped to `tag:kubernetes`.
- **ACL scoping** uses `autogroup:member` (all domain users), which — unlike `*` — excludes
  tagged/service devices and externally-shared users.

## Alternatives considered
- **hostNetwork + node join + host firewall** — documented as a fallback in `docs/Apps/croc.md`,
  but rejected as primary: needs a node on the tailnet (none are), and requires an
  `iptables` rule to pin ports to `tailscale0` or it exposes them on the LAN.
- **Tailscale Ingress** — HTTP/HTTPS only; can't carry croc's raw TCP port range.
