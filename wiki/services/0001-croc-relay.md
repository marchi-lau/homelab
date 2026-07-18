---
id: "0001"
title: "croc — private file-transfer relay (tailnet-only)"
status: active
created: 2026-07-16
updated: 2026-07-16
links: ["[[architectures/0001]]", "[[runbooks/0004]]"]
---
## Summary
Self-hosted [croc](https://github.com/schollz/croc) relay so files can be sent
peer-to-peer between **two different Tailscale users** (Taildrop only works within one
user's own devices). croc payloads are already end-to-end encrypted via PAKE; the relay
only staples the two connections. Self-hosting keeps every byte inside the WireGuard tunnel
— nothing touches the public croc relay.

## Deployment
- Namespace `croc`; image `docker.io/schollz/croc` (v10.4.13), **no command override**
  (default entrypoint is `croc relay`). 1 replica, tiny (32Mi/256Mi).
- Manifest: `clusters/homelab/apps/croc.yaml`. Docs: `docs/Apps/croc.md`.
- Ports 9009 (comms) + 9010-9013 (multiplexed data).
- `CROC_PASS` from an out-of-band Secret `croc-secret` — **deliberately not in git** so the
  password never gets committed. Create with
  `kubectl create secret generic croc-secret -n croc --from-literal=CROC_PASS="$(openssl rand -base64 24)"`.

## Exposure
Tailscale **operator** (`tailscale.com/expose: "true"`, `hostname: croc`), giving it its own
tailnet device `croc.tailb1bee0.ts.net` (100.108.179.92) with the **real ports 9009-9013**
and **zero LAN exposure**. Access is gated by a Tailscale ACL granting `autogroup:member`
(all `@delta-and-beta.com` users) to `tag:kubernetes:9009-9013`. See [[architectures/0001]]
for why operator over hostNetwork/NodePort.

## Operational notes
- **`enableServiceLinks: false` is required.** k8s injects `CROC_PORT=tcp://<clusterIP>:9009`
  (legacy Docker-links compat, because the Service is named `croc`), and croc reads
  `$CROC_PORT` as its `--port` flag → crash-loops parsing it as an int. Disabling service
  links removes the collision; croc's default ports are already `9009-9013`.
- The tag must be **`tag:kubernetes`** (what the operator already assigns); a new tag like
  `tag:croc-relay` fails `tagOwners[...]: does not exist` — the operator's OAuth client is
  scoped to `tag:kubernetes`.
- Verified end-to-end via `--no-local` (croc prefers a direct local peer and bypasses the
  relay on same-machine/LAN tests; a real relayed transfer shows the peer as a `10.42.x.x`
  pod IP).
- Client aliases live in `~/.zshrc` (`crocsend`/`crocrecv`/`crocinfo`) sourcing a `600`-perm
  `~/.croc-relay.env`. Custom code phrase = `CROC_SECRET` env var (croc v10 has **no**
  `--code` flag).

## Related
[[architectures/0001]] (exposure decision), [[runbooks/0004]] (how it was deployed).
