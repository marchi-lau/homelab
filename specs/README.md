# Homelab Service Specifications

Speckit-compatible specifications for all K8s services deployed in the homelab cluster.

## Spec Index

### Public Web Services (Cloudflare Tunnel)

| # | Service | Description | Status |
|---|---------|-------------|--------|
| 001 | [n8n](./001-n8n/spec.md) | Workflow automation platform | Deployed |
| 002 | [rustfs](./002-rustfs/spec.md) | S3-compatible object storage | Deployed |
| 003 | [monitoring](./003-monitoring/spec.md) | Prometheus/Grafana stack | Deployed |
| 004 | [string-is](./004-string-is/spec.md) | Encoding/decoding tool | Deployed |
| 005 | [it-tools](./005-it-tools/spec.md) | Web utilities collection | Deployed |
| 006 | [s-pdf](./006-s-pdf/spec.md) | Stirling PDF processor | Deployed |
| 007 | [uptime-kuma](./007-uptime-kuma/spec.md) | Uptime monitoring | Deployed |
| 008 | [homepage](./008-homepage/spec.md) | Dashboard | Deployed |
| 009 | [ai-drawio](./009-ai-drawio/spec.md) | AI-powered diagramming | Deployed |
| 010 | [excalidraw](./010-excalidraw/spec.md) | Whiteboard collaboration | Deployed |
| 011 | [miniflux](./011-miniflux/spec.md) | RSS feed reader | Deployed |
| 012 | [open-webui](./012-open-webui/spec.md) | AI chat interface | Deployed |
| 013 | [rsshub](./013-rsshub/spec.md) | RSS feed generator | Deployed |
| 014 | [www-delta-and-beta](./014-www-delta-and-beta/spec.md) | Static website | Deployed |
| 019 | [webhook-site](./019-webhook-site/spec.md) | Webhook testing tool | Deployed |

### Private MCP Services (Tailscale)

| # | Service | Description | Status |
|---|---------|-------------|--------|
| 015 | [mcp-cloudflare](./015-mcp-cloudflare/spec.md) | Cloudflare API proxy | Deployed |
| 016 | [mcp-weather](./016-mcp-weather/spec.md) | Weather API proxy | Deployed |
| 017 | [mcp-airtable](./017-mcp-airtable/spec.md) | Airtable API proxy | Deployed |
| 020 | [firecrawl](./020-firecrawl/spec.md) | Web scraping API | Deployed |
| 021 | [mcp-firecrawl](./021-mcp-firecrawl/spec.md) | MCP Firecrawl server | Deployed |

### Development Tools

| # | Service | Description | Status |
|---|---------|-------------|--------|
| 018 | [ai-workstation](./018-ai-workstation/spec.md) | Remote dev environment | Deployed |

## Conventions

### Spec Numbering
- Sequential zero-padded numbers: `001`, `002`, ... `020`
- New services get the next available number

### Directory Structure
```
specs/
├── README.md                          # This file
├── _template/
│   └── service-spec-template.md       # Template for new specs
└── NNN-service-name/
    └── spec.md                        # Service specification
```

### Spec vs Docs

| Purpose | Location |
|---------|----------|
| Technical requirements | `specs/NNN-name/spec.md` |
| K8s resource definitions | `specs/NNN-name/spec.md` |
| Dependency mapping | `specs/NNN-name/spec.md` |
| User guides | `docs/Apps/name.md` |
| Troubleshooting guides | `docs/Apps/name.md` |
| Architecture diagrams | `docs/Apps/name.md` |

### Creating a New Spec

1. Copy template: `cp -r specs/_template specs/NNN-service-name`
2. Rename: `mv specs/NNN-service-name/service-spec-template.md specs/NNN-service-name/spec.md`
3. Fill in all sections
4. Update this README index

### Speckit Commands

```bash
# Find specs by keyword
/speckit.find <keyword>

# Create new spec (for new services)
/speckit.new <service-name>
```

## Related

- [[docs/Homelab.md]] - Cluster overview
- [[CLAUDE.md]] - Agent instructions
- [[clusters/homelab/apps/]] - K8s manifests
