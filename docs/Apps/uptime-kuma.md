# Uptime Kuma

A fancy self-hosted monitoring tool for tracking uptime of services, websites, and more.

## Quick Links

- **URL**: https://status.marchi.app
- **GitHub**: https://github.com/louislam/uptime-kuma
- **Docker Hub**: https://hub.docker.com/r/louislam/uptime-kuma

---

## Deployment Info

| Property | Value |
|----------|-------|
| Namespace | `uptime-kuma` |
| Image | `louislam/uptime-kuma:1` |
| Port | 3001 |
| Ingress | Cloudflare Tunnel |
| Storage | 1Gi PVC (SQLite database) |

---

## Features

### Monitoring Types
- HTTP(s) / TCP / Ping / DNS
- Docker container status
- Steam game server
- MQTT
- SQL Server / PostgreSQL / MySQL / Redis
- Radius / Gamedig

### Notifications
- Telegram, Discord, Slack, Email
- Webhook, Pushover, PagerDuty
- Microsoft Teams, Gotify
- And 90+ more notification services

### Status Pages
- Beautiful public status pages
- Custom domain support
- Incident management
- Maintenance windows

---

## Initial Setup

1. Access https://status.marchi.app
2. Create admin account on first visit
3. Add monitors for your services

### Suggested Monitors

| Service | Type | URL/Host |
|---------|------|----------|
| n8n | HTTP(s) | https://n8n-02.marchi.app |
| Grafana | HTTP(s) | https://grafana.marchi.app |
| RustFS | HTTP(s) | https://s3-console.marchi.app |
| string-is | HTTP(s) | https://string-is.marchi.app |
| IT-Tools | HTTP(s) | https://it-tools.marchi.app |
| Stirling PDF | HTTP(s) | https://s-pdf.marchi.app |

---

## Resource Limits

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "50m"
  limits:
    memory: "256Mi"
    cpu: "500m"
```

---

## Commands

```bash
# Check pod status
kubectl get pods -n uptime-kuma

# View logs
kubectl logs -n uptime-kuma -l app=uptime-kuma

# Restart deployment
kubectl rollout restart deployment/uptime-kuma -n uptime-kuma

# Check PVC
kubectl get pvc -n uptime-kuma
```

---

## Integration with n8n

Uptime Kuma can send webhook notifications to n8n for automated incident response.

1. In Uptime Kuma: Add notification → Webhook
2. URL: `https://n8n-02.marchi.app/webhook/uptime-kuma`
3. In n8n: Create webhook trigger workflow

---

## Related

- [[../Homelab|Homelab Overview]]
- [[../Network/Cloudflare-Tunnel|Cloudflare Tunnel Setup]]
- [[Monitoring|Prometheus + Grafana]] - Metrics monitoring
- [[n8n|n8n]] - Webhook integration

## Tags

#app #monitoring #uptime-kuma #status #cloudflare
