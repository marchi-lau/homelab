# Retro log

Append-only journal of retro runs. Newest at the bottom.

## [2026-07-16] retro | scaffolded wiki (genai) + first distillation pass
Scaffolded a GenAI-proposed 4-folder structure tailored to this K3s GitOps repo and
distilled the current session into it.
- Created managed folders: `services/`, `incidents/`, `architectures/`, `runbooks/` (each with a `.prompt`).
- services: 0001 croc relay, 0002 firecrawl, 0003 AEM instances.
- incidents: 0001 master IP-flip outage (active), 0002 exit-node LAN-block false alarm,
  0003 firecrawl OOM + slow-start, 0004 ai-drawio corrupt containerd layer,
  0005 Flux/CSI controllers flapping on 4GB master (active).
- architectures: 0001 Tailscale-operator TCP exposure, 0002 4GB-master fragility,
  0003 GitOps/Flux-tracks-main flow.
- runbooks: 0001 recover master, 0002 cluster-unreachable triage, 0003 pin master IP (draft),
  0004 deploy via GitOps.
- Open/unhardened items flagged: pin master node-IP (runbooks/0003), relieve master memory
  (architectures/0002), reconcile `rosewood-aem` drift into GitOps (services/0003),
  open-webui crash-loop (noted, not yet documented as its own incident).
