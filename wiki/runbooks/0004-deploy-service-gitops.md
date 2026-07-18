---
id: "0004"
title: "Deploy / change a service via GitOps and force a Flux sync"
status: active
created: 2026-07-16
updated: 2026-07-16
links: ["[[architectures/0003]]", "[[services/0001]]"]
---
## When to use
Add or change any service. Live `kubectl` edits get reverted by Flux, so the change must go
through git `main`.

## Prerequisites
`export KUBECONFIG=~/.kube/config-s740`. Repo clone. Any secret created out-of-band first
(never in git).

## Steps
1. Edit/create `clusters/homelab/apps/<name>.yaml` and add it to
   `clusters/homelab/apps/kustomization.yaml`.
2. Create any Secret out-of-band, e.g.
   `kubectl create secret generic <name>-secret -n <ns> --from-literal=KEY="$(openssl rand -base64 24)"`.
3. **Validate before pushing:**
   ```
   kubectl kustomize clusters/homelab/apps > /dev/null      # renders?
   kubectl apply -f clusters/homelab/apps/<name>.yaml --dry-run=server
   ```
4. Commit **only the intended files** (leave unrelated working-tree changes staged out) and
   get it onto `main`. PR is the documented path but `gh pr create` fails here
   (collaborator mismatch); the working fallback is merge locally + `git push origin main`
   over SSH. Branch off `origin/main`, not another feature branch — see [[architectures/0003]].
5. **Force reconcile** (the `flux` CLI isn't on PATH locally):
   ```
   TS=$(date +%s)
   kubectl annotate gitrepository flux-system -n flux-system reconcile.fluxcd.io/requestedAt="$TS" --overwrite
   kubectl annotate kustomization  apps        -n flux-system reconcile.fluxcd.io/requestedAt="$TS" --overwrite
   ```

## Verification
```
kubectl get gitrepository flux-system -n flux-system -o jsonpath='{.status.artifact.revision}'  # = your commit
kubectl get pods -n <ns>            # rolls to the new spec, reaches Running
```

## Notes / gotchas
- Reconcile annotate can hit transient `TLS handshake timeout` on the 4GB master — retry with
  backoff (see [[architectures/0002]]).
- For a slow-starting app, add a `startupProbe` so the `livenessProbe` doesn't SIGKILL it
  mid-boot (lesson from firecrawl). Worked example of the full flow: [[services/0001]] (croc).
