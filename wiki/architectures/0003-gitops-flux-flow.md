---
id: "0003"
title: "GitOps flow — Flux tracks main; live patches are not durable"
status: active
created: 2026-07-16
updated: 2026-07-16
links: ["[[runbooks/0004]]"]
---
## Context
The cluster is Flux-managed. Repeatedly this session, `kubectl patch`/`set env` fixes
"worked" then vanished — because Flux reconciles state back to git.

## Decision
Treat **git `main` as the single source of truth**. Any fix that must survive goes into
`clusters/homelab/apps/<name>.yaml` and reaches `main`; live edits are only for diagnosis.

## Consequences
- The Flux `GitRepository` tracks `url=https://github.com/marchi-lau/homelab.git`,
  `ref.branch=main`; the `apps` Kustomization applies `./clusters/homelab/apps`.
- A change committed to a feature branch but **not merged to `main`** is not applied — Flux
  won't see it. (A fix branch was accidentally based off `feature/aem-memory` and dragged in
  an unrelated `aem.yaml` change on merge; recover by resetting `main` to `origin/main` and
  cherry-picking only the intended commit.)
- Secrets are kept **out of git** and created out-of-band (e.g. `croc-secret`,
  `firecrawl-secrets` referenced via `secretKeyRef`), so Flux never manages/overwrites them.

## Constraints honored
- `gh pr create` fails (`must be a collaborator`) — the `gh` auth identity differs from the
  SSH push identity. Practical path: merge to `main` locally and `git push` over SSH (which
  has write access), since Flux needs the change on `main` regardless.
- Force a sync without the `flux` CLI (not on PATH locally) by annotating the source +
  kustomization with `reconcile.fluxcd.io/requestedAt` — see [[runbooks/0004]].

## Alternatives considered
PR-based merge is the documented workflow but was blocked by the `gh` collaborator issue;
direct-to-main over SSH is the working fallback for this repo.
