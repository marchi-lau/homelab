---
id: "0003"
title: "AEM author instances (aem + rosewood-aem)"
status: active
created: 2026-07-16
updated: 2026-07-16
links: []
---
## Summary
Two AEM **author** instances run on the cluster, both on the AEM Cloud SDK image
`aemdesign/aem:sdk-2026.1.23963`, run mode `author,crx3,crx3tar,nosamplecontent` (clean
repo, no sample content).

| Namespace | Pod age (at 2026-07-16) | Purpose |
|-----------|--------------------------|---------|
| `aem` | ~8 days | The original author instance (in git: `clusters/homelab/apps/aem.yaml`) |
| `rosewood-aem` | ~few hours (recent) | Rosewood AEM archive instance |

## Deployment
- `aem`: 8Gi memory limit, JVM `-Xms4096m -Xmx6144m`, 10Gi `synology-nfs` PVC for the crx
  repository, TZ Asia/Hong_Kong. Manifest `clusters/homelab/apps/aem.yaml`.
- Each namespace also has its own Tailscale operator proxy pod (`ts-aem-*`, `ts-...`).

## Exposure
- `aem`: Cloudflare tunnel `aem.delta-and-beta.com` **and** Tailscale `aem.tailb1bee0.ts.net`.
- Each instance's Tailscale Ingress spins up a proxy pod in the `tailscale` namespace.

## Operational notes
- **`rosewood-aem` appears to be deployed OUTSIDE GitOps** — only `aem.yaml` (the `aem`
  namespace) is in the repo, and `rosewood-aem` was created recently and manually. This is
  drift: Flux does not manage it and it isn't captured in git. Worth reconciling.
- The `aem` repository sits on `synology-nfs`; an initContainer does `chown 1000:1000` on the
  repository path to work around NFS `root_squash` (per `docs/Homelab.md` lessons).
- Related infra work: Rosewood AEM archive EC2/IAM is tracked in Jira ITT-23 (AWS side, not
  k3s); a subtask ITT-65 requested an SSH allowlist for the `ai-connector` egress IP
  (`104.64.214.231/32`).

## Related
(none yet)
