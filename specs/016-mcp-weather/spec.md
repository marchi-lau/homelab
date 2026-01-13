# Service Specification: MCP Weather Service

> Spec Number: 016
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/mcp-weather.yaml

## Overview

MCP Weather is a Model Context Protocol (MCP) server that provides AI assistants with weather information. It uses the Open-Meteo API for weather data and exposes tools for current conditions, forecasts, and air quality. Accessed privately via Tailscale.

## Service Requirements

### SR-1: Weather Data Access
- **Need:** AI assistants need weather information capabilities
- **Solution:** MCP server with weather tools
- **Verification:** `curl -s https://mcp-weather.<tailnet>.ts.net/sse`

### SR-2: Private Access
- **Need:** MCP services should be private
- **Solution:** Tailscale ingress with TLS
- **Verification:** Only accessible via Tailscale network

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `mcp-weather` |
| Image | `dog830228/mcp_weather_server:latest` |
| Replicas | 1 |
| Strategy | RollingUpdate |

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 64Mi | 256Mi |
| CPU | 50m | 200m |

### Health Probes

| Probe | Type | Port | Path | Initial Delay |
|-------|------|------|------|---------------|
| Readiness | TCP | 8080 | N/A | 10s |
| Liveness | TCP | 8080 | N/A | 15s |

## Networking

| Property | Value |
|----------|-------|
| Service Type | ClusterIP |
| Port | 8080 |
| Ingress Class | tailscale |
| Public URL | N/A |
| Private URL | https://mcp-weather.<tailnet>.ts.net |

## Storage

| Property | Value |
|----------|-------|
| Storage Class | none |
| Size | N/A |
| Mount Path | N/A |
| Access Mode | N/A |

## Configuration

### Container Command

```sh
uv run python -m mcp_weather_server --mode sse
```

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| N/A | N/A | Uses Open-Meteo (no API key needed) |

### Secrets

| Secret | Keys | Purpose |
|--------|------|---------|
| N/A | N/A | No secrets required |

## Dependencies

### Requires
- Tailscale operator
- Flux GitOps

### Required By
- Claude Code / MCP clients

## Operations

### Status Check
```bash
kubectl get pods -n mcp-weather
kubectl logs -n mcp-weather -l app=mcp-weather --tail=50
```

### Restart
```bash
kubectl rollout restart deployment/mcp-weather -n mcp-weather
```

### Update
1. Edit `clusters/homelab/apps/mcp-weather.yaml`
2. Commit and push to feature branch
3. Create PR and merge to main
4. Flux auto-syncs, or force: `flux reconcile kustomization apps --with-source`

## Troubleshooting

### Weather data unavailable
- **Symptom:** MCP tools return errors or empty data
- **Cause:** Open-Meteo API unreachable
- **Fix:** Check network connectivity, try again later

## Related

- External: https://open-meteo.com/

## Tags

#homelab #k8s #mcp #weather #api #tailscale
